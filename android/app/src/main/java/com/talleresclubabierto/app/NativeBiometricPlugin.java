package com.talleresclubabierto.app;

import android.app.Activity;
import android.os.Build;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;

import androidx.annotation.NonNull;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.PluginMethod;

import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.util.concurrent.Executor;

@CapacitorPlugin(name = "NativeBiometric")
public class NativeBiometricPlugin extends Plugin {
    private static final String KEYSTORE = "AndroidKeyStore";
    private static final String DEFAULT_ALIAS = "club_abierto_identity_v1";

    private int authenticators() {
        return BiometricManager.Authenticators.BIOMETRIC_STRONG |
               BiometricManager.Authenticators.DEVICE_CREDENTIAL;
    }

    private String alias(PluginCall call) {
        String value = call.getString("keyAlias", DEFAULT_ALIAS);
        return (value == null || value.trim().isEmpty()) ? DEFAULT_ALIAS : value.trim();
    }

    @PluginMethod
    public void isAvailable(PluginCall call) {
        int result = BiometricManager.from(getContext()).canAuthenticate(authenticators());
        JSObject out = new JSObject();
        out.put("available", result == BiometricManager.BIOMETRIC_SUCCESS);
        out.put("status", result);
        call.resolve(out);
    }

    @PluginMethod
    public void createKey(PluginCall call) {
        try {
            String alias = alias(call);
            KeyStore store = KeyStore.getInstance(KEYSTORE);
            store.load(null);
            if (store.containsAlias(alias)) store.deleteEntry(alias);

            KeyPairGenerator generator = KeyPairGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_RSA, KEYSTORE);
            KeyGenParameterSpec spec = new KeyGenParameterSpec.Builder(
                alias, KeyProperties.PURPOSE_SIGN | KeyProperties.PURPOSE_VERIFY)
                .setDigests(KeyProperties.DIGEST_SHA256)
                .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                .setUserAuthenticationRequired(true)
                .setInvalidatedByBiometricEnrollment(true)
                .build();
            generator.initialize(spec);
            KeyPair pair = generator.generateKeyPair();

            JSObject out = new JSObject();
            out.put("keyAlias", alias);
            out.put("publicKeySpkiB64", Base64.encodeToString(
                pair.getPublic().getEncoded(), Base64.NO_WRAP));
            call.resolve(out);
        } catch (Exception e) {
            call.reject("No se pudo crear la clave biométrica", e);
        }
    }

    @PluginMethod
    public void getPublicKey(PluginCall call) {
        try {
            String alias = alias(call);
            KeyStore store = KeyStore.getInstance(KEYSTORE);
            store.load(null);
            java.security.cert.Certificate cert = store.getCertificate(alias);
            if (cert == null) {
                call.reject("La clave biométrica no existe");
                return;
            }
            JSObject out = new JSObject();
            out.put("keyAlias", alias);
            out.put("publicKeySpkiB64", Base64.encodeToString(
                cert.getPublicKey().getEncoded(), Base64.NO_WRAP));
            call.resolve(out);
        } catch (Exception e) {
            call.reject("No se pudo leer la clave biométrica", e);
        }
    }

    @PluginMethod
    public void signChallenge(PluginCall call) {
        String challenge = call.getString("challenge");
        if (challenge == null || challenge.isEmpty()) {
            call.reject("Challenge requerido");
            return;
        }
        final String keyAlias = alias(call);
        final PluginCall savedCall = call;
        bridge.saveCall(call);

        getActivity().runOnUiThread(() -> {
            try {
                KeyStore store = KeyStore.getInstance(KEYSTORE);
                store.load(null);
                PrivateKey key = (PrivateKey) store.getKey(keyAlias, null);
                if (key == null) {
                    savedCall.reject("La clave biométrica no existe");
                    bridge.releaseCall(savedCall);
                    return;
                }

                Signature signature = Signature.getInstance("SHA256withRSA");
                signature.initSign(key);

                Executor executor = ContextCompat.getMainExecutor(getContext());
                BiometricPrompt prompt = new BiometricPrompt(
                    getActivity(),
                    executor,
                    new BiometricPrompt.AuthenticationCallback() {
                        @Override
                        public void onAuthenticationError(int errorCode, @NonNull CharSequence errString) {
                            savedCall.reject("Validación biométrica cancelada: " + errString);
                            bridge.releaseCall(savedCall);
                        }

                        @Override
                        public void onAuthenticationSucceeded(@NonNull BiometricPrompt.AuthenticationResult result) {
                            try {
                                Signature crypto = result.getCryptoObject() != null
                                    ? result.getCryptoObject().getSignature() : null;
                                if (crypto == null) {
                                    savedCall.reject("Android no devolvió la clave criptográfica");
                                } else {
                                    crypto.update(challenge.getBytes(StandardCharsets.UTF_8));
                                    byte[] signed = crypto.sign();
                                    JSObject out = new JSObject();
                                    out.put("signatureB64", Base64.encodeToString(signed, Base64.NO_WRAP));
                                    out.put("keyAlias", keyAlias);
                                    savedCall.resolve(out);
                                }
                            } catch (Exception e) {
                                savedCall.reject("No se pudo firmar el desafío biométrico", e);
                            } finally {
                                bridge.releaseCall(savedCall);
                            }
                        }
                    });

                BiometricPrompt.CryptoObject cryptoObject = new BiometricPrompt.CryptoObject(signature);
                BiometricPrompt.PromptInfo info = new BiometricPrompt.PromptInfo.Builder()
                    .setTitle("Validar identidad")
                    .setSubtitle("Talleres Club Abierto")
                    .setAllowedAuthenticators(authenticators())
                    .build();
                prompt.authenticate(info, cryptoObject);
            } catch (Exception e) {
                savedCall.reject("No se pudo iniciar la validación biométrica", e);
                bridge.releaseCall(savedCall);
            }
        });
    }
}
