import { cp, mkdir, readFile, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawnSync } from 'node:child_process';

const directory = dirname(fileURLToPath(import.meta.url));
const app = resolve(directory, 'ios/App/App');
const start = '// BEGIN CLUB ABIERTO IOS ROUTER';
const end = '// END CLUB ABIERTO IOS ROUTER';
const delegate = resolve(app, 'AppDelegate.swift');
let source = await readFile(delegate, 'utf8');
const custom = await readFile(resolve(directory, 'native/ClubAbiertoRouter.swift'), 'utf8');
const existing = source.indexOf(start);
if (existing !== -1) {
  const finish = source.indexOf(end, existing);
  if (finish === -1) throw new Error('Incomplete native router section');
  source = source.slice(0, existing) + source.slice(finish + end.length);
}
await writeFile(delegate, source.trimEnd() + '\n\n' + start + '\n' + custom.trim() + '\n' + end + '\n');

const storyboardPath = resolve(app, 'Base.lproj/Main.storyboard');
let storyboard = await readFile(storyboardPath, 'utf8');
const original = 'customClass="CAPBridgeViewController" customModule="Capacitor"';
const replacement = 'customClass="ClubAbiertoViewController" customModule="App"';
if (storyboard.includes(original)) storyboard = storyboard.replace(original, replacement);
else if (!storyboard.includes(replacement)) throw new Error('Unexpected Capacitor Main.storyboard');
await writeFile(storyboardPath, storyboard);
// Capacitor 8.5 creates the root controller in SceneDelegate, not the storyboard.
const scenePath = resolve(app, 'SceneDelegate.swift');
let scene = await readFile(scenePath, 'utf8');
const defaultController = 'window?.rootViewController = CAPBridgeViewController()';
const customController = 'window?.rootViewController = ClubAbiertoViewController()';
if (scene.includes(defaultController)) scene = scene.replace(defaultController, customController);
else if (!scene.includes(customController)) throw new Error('Unexpected Capacitor SceneDelegate');
await writeFile(scenePath, scene);
await cp(resolve(directory, 'native/LaunchScreen.storyboard'), resolve(app, 'Base.lproj/LaunchScreen.storyboard'));

const iconset = resolve(app, 'Assets.xcassets/AppIcon.appiconset');
await mkdir(iconset, { recursive: true });
const icon = resolve(directory, 'android-icon.png');
const resize = spawnSync('sips', ['-z', '1024', '1024', icon, '--out', resolve(iconset, 'AppIcon-1024.png')], { stdio: 'inherit' });
if (resize.error) throw resize.error;
if (resize.status !== 0) throw new Error('Could not prepare the iOS app icon');
await writeFile(resolve(iconset, 'Contents.json'), JSON.stringify({
  images: [{ filename: 'AppIcon-1024.png', idiom: 'universal', platform: 'ios', size: '1024x1024' }],
  info: { author: 'xcode', version: 1 }
}, null, 2) + '\n');
const mark = resolve(app, 'Assets.xcassets/BrandMark.imageset');
await mkdir(mark, { recursive: true });
await cp(icon, resolve(mark, 'brand.png'));
await writeFile(resolve(mark, 'Contents.json'), JSON.stringify({
  images: [{ filename: 'brand.png', idiom: 'universal' }], info: { author: 'xcode', version: 1 }
}, null, 2) + '\n');

// Keep version/device settings in the exported Xcode project as well as CI.
const projectPath = resolve(directory, 'ios/App/App.xcodeproj/project.pbxproj');
let project = await readFile(projectPath, 'utf8');
project = project.replace(/MARKETING_VERSION = [^;]+;/g, 'MARKETING_VERSION = 1.9;')
  .replace(/TARGETED_DEVICE_FAMILY = [^;]+;/g, 'TARGETED_DEVICE_FAMILY = 1;');
await writeFile(projectPath, project);
console.log('iOS: rutas de Comunidad Formativa, identidad visual y versión configuradas.');

