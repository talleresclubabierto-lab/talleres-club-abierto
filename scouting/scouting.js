(() => {
  'use strict';

  const API_URL = 'https://sziuyjicqyxnmbgtbopg.supabase.co/functions/v1/scouting-api';
  const SESSION_KEY = 'TD_club_session_v1';
  const OTHER_CATEGORY = '__other__';
  const STATUS = Object.freeze({
    recibida: 'Recibida',
    en_revision: 'En revisión',
    informacion_solicitada: 'Información solicitada',
    en_seguimiento: 'En seguimiento',
    contactado: 'Contactado',
    visitado: 'Visitado',
    convocado_a_prueba: 'Convocado a prueba',
    prueba_realizada: 'Prueba realizada',
    no_avanza: 'No avanza',
    cerrada: 'Cerrada'
  });
  const DASHBOARD_METRICS = Object.freeze({
    'metric-recomendados': 'total_player_references',
    'metric-contactados': 'contacted',
    'metric-visitados': 'visited',
    'metric-convocados-a-prueba': 'invited_to_trial',
    'metric-prueba-realizada': 'trial_completed',
    'metric-no-avanzan': 'not_advanced'
  });
  const PROOF_STATUS = Object.freeze({
    registrada: 'Registrada en auditoría',
    preparada: 'Preparada para anclaje',
    enviada: 'Anclaje enviado, pendiente de confirmación',
    anclada: 'Anclaje confirmado'
  });
  const VIDEO_HOSTS = new Set(['youtube.com', 'www.youtube.com', 'm.youtube.com', 'youtu.be', 'vimeo.com', 'www.vimeo.com', 'player.vimeo.com']);
  const TRANSFERMARKT_HOSTS = new Set(['transfermarkt.com', 'transfermarkt.com.ar', 'transfermarkt.es', 'transfermarkt.de', 'transfermarkt.fr', 'transfermarkt.it', 'transfermarkt.pt', 'transfermarkt.co.uk', 'transfermarkt.nl']);
  const $ = (id) => document.getElementById(id);
  const channels = new Map();
  const timers = new Map();
  const state = {
    actor: null, bootstrap: null, expired: false, activeToken: '', sessionGeneration: 0, activeTab: 'mine', panelContext: initialPanelContext(),
    clubs: new Map(), players: new Map(), clubsCursor: null, playersCursor: null, clubsQuery: null, playersQuery: null,
    selectedClub: null, selectedPlayer: null, clubAutoCompetition: false, playerAutoTransfermarktUrl: null, playerAutoAge: null, createRequestId: null, createPending: null,
    createBusy: false, successId: null, currentDetailId: null,
    list: { items: [], cursor: null, loaded: false, query: null },
    dashboard: { data: null, loaded: false },
    rankedPlayerFilter: null,
    referenceRecommendation: null,
    mutations: new Map()
  };

  class ApiError extends Error {
    constructor(message, code = 'REQUEST_FAILED', status = 0) {
      super(message); this.name = 'ApiError'; this.code = code; this.status = status;
    }
  }

  function node(tag, className, text) {
    const result = document.createElement(tag);
    if (className) result.className = className;
    if (text !== undefined && text !== null) result.textContent = String(text);
    return result;
  }

  function uuid() {
    if (globalThis.crypto?.randomUUID) return globalThis.crypto.randomUUID();
    const bytes = globalThis.crypto.getRandomValues(new Uint8Array(16));
    bytes[6] = (bytes[6] & 15) | 64; bytes[8] = (bytes[8] & 63) | 128;
    const hex = [...bytes].map((value) => value.toString(16).padStart(2, '0')).join('');
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
  }

  function token() {
    try { return sessionStorage.getItem(SESSION_KEY) || ''; }
    catch (_) { return ''; }
  }

  function initialPanelContext() {
    return new URLSearchParams(window.location.search).get('panel_context') === 'admin' ? 'admin' : 'socio';
  }

  function canRecommend() { return Boolean(state.actor) && state.panelContext === 'socio'; }
  function canManage(recommendation) { return state.panelContext === 'admin' && state.actor?.role === 'admin' && recommendation.can_manage === true; }

  function applyPanelContext(value) {
    if (!['socio', 'admin'].includes(value)) return;
    const changed = state.panelContext !== value;
    state.panelContext = value;
    $('tab-recommend').hidden = !canRecommend();
    $('dashboard-recommend').hidden = !canRecommend();
    $('create-submit').disabled = !canRecommend() || state.createBusy;
    if (changed && $('detail-dialog').open) $('detail-dialog').close();
    if (state.actor && state.activeTab === 'recommend' && !canRecommend()) activateTab('mine');
    else if (changed && state.actor && state.list.loaded) renderList();
  }

  function date(value) {
    const parsed = new Date(value);
    if (!value || Number.isNaN(parsed.getTime())) return 'Fecha no disponible';
    return new Intl.DateTimeFormat('es-AR', {
      dateStyle: 'medium', timeStyle: 'short', hour12: false, timeZone: 'America/Argentina/Buenos_Aires'
    }).format(parsed);
  }

  function shortDate(value) {
    if (typeof value !== 'string' || !value) return null;
    const calendarOnly = /^\d{4}-\d{2}-\d{2}$/.test(value);
    const parsed = new Date(calendarOnly ? `${value}T12:00:00Z` : value);
    if (Number.isNaN(parsed.getTime())) return null;
    return new Intl.DateTimeFormat('es-AR', { dateStyle: 'medium', timeZone: calendarOnly ? 'UTC' : 'America/Argentina/Buenos_Aires' }).format(parsed);
  }

  function knownAge(value) {
    if (value === null || value === undefined || value === '') return null;
    const age = Number(value);
    return Number.isInteger(age) && age >= 1 && age <= 100 ? age : null;
  }

  function ageLabel(player) {
    const age = knownAge(player?.age_at_recommendation);
    return age === null ? 'Sin edad informada' : `${age} ${age === 1 ? 'año' : 'años'}`;
  }

  function authorLabel(author) {
    const number = author?.numero_socio;
    const membership = number === null || number === undefined || String(number).trim() === '' ? 'N° de socio no informado' : `N° ${number}`;
    return `${membership} · ${author?.name || 'Socio de Club Abierto'}`;
  }

  function verifiedMarketValue(value) {
    if (!value || value.verification !== 'verified' || value.source !== 'Transfermarkt') return null;
    const amount = value.amount === null || value.amount === undefined || value.amount === '' ? NaN : Number(value.amount);
    const currency = typeof value.currency === 'string' ? value.currency.toUpperCase() : '';
    const href = safeUrl(value.source_url, 'transfermarkt');
    const asOf = shortDate(value.as_of);
    const verifiedAt = shortDate(value.verified_at);
    if (!Number.isFinite(amount) || amount < 0 || !/^[A-Z]{3}$/.test(currency) || !href || !/\/profil\/spieler\/\d+(?:\/|$)/.test(new URL(href).pathname) || !asOf || !verifiedAt) return null;
    try {
      const formatted = new Intl.NumberFormat('es-AR', { style: 'currency', currency, currencyDisplay: 'code', minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(amount);
      return { formatted, href, asOf, verifiedAt };
    } catch (_) { return null; }
  }

  function appendMarketValue(container, raw) {
    const value = verifiedMarketValue(raw);
    container.append(node('span', 'market-value', value ? value.formatted : 'Sin valor informado'));
    if (!value) return;
    const source = node('a', 'market-source', 'Transfermarkt ↗');
    source.href = value.href; source.target = '_blank'; source.rel = 'noopener noreferrer';
    const provenance = node('span', 'market-provenance');
    provenance.append(source, node('span', '', `Valor al ${value.asOf} · Verificado el ${value.verifiedAt}`));
    container.append(provenance);
  }

  function message(error) {
    return error instanceof Error ? error.message : 'No pudimos completar la operación. Intentá nuevamente.';
  }

  function setFeedback(idOrElement, text, type = 'error', focus = false) {
    const target = typeof idOrElement === 'string' ? $(idOrElement) : idOrElement;
    target.textContent = text || '';
    target.hidden = !text;
    target.className = `feedback${type === 'error' ? '' : ` feedback-${type}`}`;
    if (focus && text) target.focus();
  }

  function setBoot(title, description, options = {}) {
    $('application').hidden = true;
    $('boot-panel').hidden = false;
    $('boot-title').textContent = title;
    $('boot-message').textContent = description;
    $('boot-spinner').hidden = !options.loading;
    $('boot-retry').hidden = !options.retry;
    $('login-link').hidden = !options.login;
    if (options.focus) $('boot-title').focus();
  }

  function clearSessionState() {
    state.sessionGeneration += 1;
    for (const [key] of channels) cancelChannel(key);
    for (const timer of timers.values()) clearTimeout(timer);
    timers.clear();
    if ($('detail-dialog').open) $('detail-dialog').close();
    state.actor = null; state.bootstrap = null; state.activeToken = ''; state.activeTab = 'mine';
    state.clubs.clear(); state.players.clear(); state.mutations.clear();
    state.selectedClub = null; state.selectedPlayer = null; state.playerAutoTransfermarktUrl = null; state.playerAutoAge = null; state.createPending = null;
    state.createRequestId = null; state.successId = null; state.currentDetailId = null; state.createBusy = false;
    state.clubAutoCompetition = false; state.clubsQuery = null; state.playersQuery = null;
    state.list = { items: [], cursor: null, loaded: false, query: null };
    state.dashboard = { data: null, loaded: false };
    state.rankedPlayerFilter = null; state.referenceRecommendation = null;
    $('recommend-form').reset();
    updateClubReference(); updatePlayerReview(); updateReferenceNotice();
    for (const id of ['mine-list', 'detail-body']) $(id).replaceChildren();
    for (const id of ['success-description', 'selected-club-name', 'selected-club-description', 'actor-label', 'mine-count']) $(id).textContent = '';
    $('mine-query').value = ''; $('mine-only').checked = false;
    for (const id of Object.keys(DASHBOARD_METRICS)) $(id).textContent = '—';
    $('dashboard-total').textContent = 'Consultando los totales globales del scouting.';
    $('dashboard-updated').textContent = ''; $('dashboard-updated').hidden = true;
    $('ranking-list').replaceChildren(); $('ranking-list').hidden = true;
    $('ranking-empty').textContent = 'El listado se mostrará cuando termine la consulta del tablero.'; $('ranking-empty').hidden = false;
    $('player-filter').hidden = true; $('player-filter-name').textContent = '';
    $('dashboard-metrics').setAttribute('aria-busy', 'false');
    setFeedback('dashboard-feedback', ''); setFeedback('mine-feedback', '');
    $('club-choice').replaceChildren(option('', 'Elegí una provincia para buscar', true));
    $('player-choice').replaceChildren(option('', 'Seleccioná una categoría', true));
    setFeedback('create-feedback', '');
    $('create-success').hidden = true; $('recommend-layout').hidden = false;
    $('create-fields').disabled = false;
    $('create-submit').disabled = true; $('create-submit').textContent = 'Enviar recomendación ↗';
    $('tab-recommend').hidden = true; $('dashboard-recommend').hidden = true;
    $('actor-label').hidden = true;
  }

  function expireSession(description = 'Tu sesión ya no está disponible. Ingresá a Club Abierto y abrí nuevamente Scouting colaborativo.') {
    state.expired = true;
    clearSessionState();
    setBoot('Volvé a ingresar', description, { login: true, focus: true });
  }

  function checkSessionIdentity() {
    if (state.activeToken && token() !== state.activeToken) {
      expireSession('La sesión cambió. Volvé a abrir scouting desde el panel de la cuenta con la que ingresaste.');
      return false;
    }
    return true;
  }

  async function api(action, payload = {}, externalSignal) {
    const sessionToken = token();
    const generation = state.sessionGeneration;
    if (state.activeToken && sessionToken !== state.activeToken) {
      expireSession('La sesión cambió. Volvé a abrir scouting desde tu panel.');
      throw new ApiError('La sesión cambió.', 'SESSION_CHANGED', 401);
    }
    if (!sessionToken || state.expired) {
      expireSession();
      throw new ApiError('La sesión venció. Volvé a ingresar.', 'SESSION_EXPIRED', 401);
    }
    const controller = new AbortController();
    let timedOut = false;
    const abort = () => controller.abort();
    if (externalSignal?.aborted) abort();
    externalSignal?.addEventListener('abort', abort, { once: true });
    const timeout = setTimeout(() => { timedOut = true; controller.abort(); }, 25000);
    try {
      const response = await fetch(API_URL, {
        method: 'POST', mode: 'cors', cache: 'no-store', credentials: 'omit',
        headers: { 'Content-Type': 'application/json', 'X-Club-Session': sessionToken },
        body: JSON.stringify({ action, payload }), signal: controller.signal
      });
      let data;
      try { data = await response.json(); }
      catch (_) { throw new ApiError('La respuesta no pudo confirmarse. Intentá nuevamente.', 'INVALID_RESPONSE', response.status >= 400 ? response.status : 502); }
      if (generation !== state.sessionGeneration) throw new DOMException('Session context changed', 'AbortError');
      if (token() !== sessionToken || state.expired) {
        expireSession('La sesión cambió. Volvé a abrir scouting desde tu panel.');
        throw new ApiError('La sesión cambió.', 'SESSION_CHANGED', 401);
      }
      if (!response.ok || data?.ok !== true) {
        const code = typeof data?.error?.code === 'string' ? data.error.code : 'REQUEST_FAILED';
        const description = typeof data?.error?.message === 'string' ? data.error.message : 'No pudimos completar la operación. Intentá nuevamente.';
        if (response.status === 401 || ['SESSION_EXPIRED', 'INVALID_SESSION', 'SESSION_REQUIRED', 'UNAUTHORIZED'].includes(code)) expireSession();
        throw new ApiError(description, code, response.status);
      }
      return data;
    } catch (error) {
      if (generation !== state.sessionGeneration && !state.expired) throw new DOMException('Session context changed', 'AbortError');
      if (externalSignal?.aborted) throw new DOMException('Request cancelled', 'AbortError');
      if (error?.name === 'AbortError' && generation !== state.sessionGeneration) throw error;
      if (error instanceof ApiError) throw error;
      if (timedOut) throw new ApiError('La respuesta está demorando más de lo esperado. Podés reintentar.', 'TIMEOUT', 0);
      throw new ApiError('No pudimos conectarnos. Comprobá tu conexión e intentá nuevamente.', 'NETWORK_ERROR', 0);
    } finally {
      clearTimeout(timeout);
      externalSignal?.removeEventListener('abort', abort);
    }
  }

  function cancelChannel(key) {
    const previous = channels.get(key);
    if (previous) previous.controller.abort();
    channels.delete(key);
  }

  function requestChannel(key) {
    cancelChannel(key);
    const current = { controller: new AbortController(), id: Symbol(key) };
    channels.set(key, current);
    return { signal: current.controller.signal, current: () => channels.get(key) === current };
  }

  function debounce(key, callback, delay = 320) {
    clearTimeout(timers.get(key));
    timers.set(key, setTimeout(callback, delay));
  }

  function clearDebounce(key) { clearTimeout(timers.get(key)); timers.delete(key); }
  function uncertain(error) { return error instanceof ApiError && (error.status === 0 || error.status >= 500); }
  function cancelled(error) { return error?.name === 'AbortError' || state.expired; }
  function route() { return document.querySelector('[name="search-route"]:checked')?.value || 'province'; }
  function manualClub() { return $('manual-club-toggle').checked; }
  function category() { return $('player-category').value === OTHER_CATEGORY ? $('custom-category').value.trim() : $('player-category').value; }

  function option(value, text, disabled = false) {
    const result = new Option(String(text), String(value)); result.disabled = disabled; return result;
  }

  function replaceOptions(select, choices, placeholder) {
    select.replaceChildren(option('', placeholder));
    for (const entry of choices) select.append(option(entry.value, entry.label));
  }

  function safeUrl(raw, kind) {
    if (!raw || typeof raw !== 'string' || raw.length > 2048 || /[\s\\]/.test(raw)) return null;
    let parsed;
    try { parsed = new URL(raw); } catch (_) { return null; }
    if (parsed.protocol !== 'https:' || parsed.username || parsed.password || (parsed.port && parsed.port !== '443')) return null;
    const hostname = parsed.hostname.toLowerCase();
    if (kind === 'video' && (!VIDEO_HOSTS.has(hostname) || !/^https:\/\/((www\.|m\.)?youtube\.com|youtu\.be|(www\.|player\.)?vimeo\.com)\/[^\s\\]+$/.test(parsed.href))) return null;
    if (kind === 'transfermarkt') {
      const base = hostname.replace(/^www\./, '');
      if (!TRANSFERMARKT_HOSTS.has(base) || !/^https:\/\/(www\.)?transfermarkt\.(com|com\.ar|es|de|co\.uk|it|fr|pt|nl)\/[a-zA-Z0-9_/%.-]+\/(profil\/spieler|startseite\/verein|kader\/verein)\/[0-9]+(\/[^?#]*)?(\?[^#]*)?(#.*)?$/.test(parsed.href)) return null;
    }
    if (kind === 'explorer' && !['polygonscan.com', 'amoy.polygonscan.com'].includes(hostname)) return null;
    return parsed.href;
  }

  function clearAutoPlayerProfile() {
    const input = $('transfermarkt-url');
    if (state.playerAutoTransfermarktUrl && safeUrl(input.value.trim(), 'transfermarkt') === state.playerAutoTransfermarktUrl) {
      input.value = ''; input.setCustomValidity(''); input.removeAttribute('aria-invalid');
    }
    state.playerAutoTransfermarktUrl = null;
  }

  function clearAutoPlayerAge() {
    if (state.playerAutoAge !== null && knownAge($('player-age').value) === state.playerAutoAge) $('player-age').value = '';
    state.playerAutoAge = null;
  }

  function autofillPlayerProfile(player) {
    const input = $('transfermarkt-url');
    const current = input.value.trim();
    const canReplace = !current || Boolean(state.playerAutoTransfermarktUrl && safeUrl(current, 'transfermarkt') === state.playerAutoTransfermarktUrl);
    const candidate = safeUrl(player?.transfermarkt_url, 'transfermarkt');
    const profile = candidate && /\/profil\/spieler\/\d+(?:\/|$)/.test(new URL(candidate).pathname) ? candidate : null;
    state.playerAutoTransfermarktUrl = null;
    if (!canReplace) return;
    input.value = profile || '';
    input.setCustomValidity(''); input.removeAttribute('aria-invalid');
    state.playerAutoTransfermarktUrl = profile;
  }

  function appendLink(container, raw, label, kind) {
    const href = safeUrl(raw, kind);
    if (!href) return;
    const link = node('a', 'detail-link', `${label} ↗`);
    link.href = href; link.target = '_blank'; link.rel = 'noopener noreferrer';
    container.append(link);
  }

  function goBack(event) {
    event.preventDefault();
    if (window.parent !== window) {
      window.parent.postMessage({ type: 'club-scouting-back' }, window.location.origin);
      return;
    }
    let sameOrigin = false;
    try { sameOrigin = new URL(document.referrer).origin === window.location.origin; } catch (_) { /* No referrer. */ }
    if (sameOrigin && window.history.length > 1) window.history.back();
    else window.location.assign('/index.html');
  }

  async function boot() {
    state.expired = false;
    if (!token()) {
      setBoot('Ingresá desde tu panel', 'Scouting colaborativo está disponible con tu sesión de Club Abierto. Ingresá a tu panel y abrí esta sección desde allí.', { login: true });
      return;
    }
    state.activeToken = token();
    setBoot('Preparando scouting', 'Estamos verificando tu sesión.', { loading: true });
    const request = requestChannel('bootstrap');
    try {
      const data = await api('bootstrap', {}, request.signal);
      if (!request.current()) return;
      if (!data.actor || !['socio', 'admin'].includes(data.actor.role)) throw new ApiError('Tu sesión no tiene acceso a esta sección.', 'ACCESS_DENIED', 403);
      state.actor = data.actor;
      state.bootstrap = data;
      initialiseForm(data);
      $('actor-label').textContent = `${data.actor.role === 'admin' ? 'Administración' : 'Socio'} · ${data.actor.numero_socio}`;
      $('actor-label').hidden = false;
      applyPanelContext(state.panelContext);
      $('boot-panel').hidden = true;
      $('application').hidden = false;
      $('mine-only').checked = location.hash === '#mis-recomendaciones';
      activateTab(location.hash === '#recomendar' && canRecommend() ? 'recommend' : 'mine');
    } catch (error) {
      if (!request.current() || cancelled(error)) return;
      setBoot('No pudimos abrir scouting', message(error), { retry: true, login: error.status === 403 });
    }
  }

  function initialiseForm(data) {
    const provinces = (Array.isArray(data.provinces) ? data.provinces : []).map((entry) => ({ value: entry, label: entry }));
    replaceOptions($('club-province'), provinces, 'Seleccioná una provincia');
    replaceOptions($('manual-province'), provinces, 'Seleccioná una provincia');
    restoreCompetitions();
    const categories = (Array.isArray(data.categories) ? data.categories : []).filter((item) => !/^otra(?: categoría)?$/i.test(item)).map((item) => ({ value: item, label: item }));
    categories.push({ value: OTHER_CATEGORY, label: 'Otra categoría' });
    replaceOptions($('player-category'), categories, 'Seleccioná una categoría');
    replaceOptions($('player-position'), (Array.isArray(data.positions) ? data.positions : []).map((item) => ({ value: item, label: item })), 'Seleccioná una posición');
    replaceOptions($('mine-status'), Object.entries(STATUS).map(([value, label]) => ({ value, label })), 'Todos los estados');
    const clubCount = Math.max(0, Number(data.catalogue?.club_count) || 0);
    const playerCount = Math.max(0, Number(data.catalogue?.player_count) || 0);
    const empty = clubCount === 0;
    $('catalogue-notice').hidden = false;
    $('catalogue-notice').textContent = `Catálogo de Argentina: ${clubCount.toLocaleString('es-AR')} ${clubCount === 1 ? 'club' : 'clubes'} y ${playerCount.toLocaleString('es-AR')} ${playerCount === 1 ? 'jugador registrado' : 'jugadores registrados'}. La cobertura de ligas, categorías y planteles es parcial. Si falta el equipo, usá Otro club. También podés recomendar un jugador cargando sus datos manualmente.`;
    $('manual-club-toggle').checked = empty;
    setManualClub(false);
    updateRoute(false);
  }

  function activateTab(name, focus = false) {
    if (name === 'recommend' && !canRecommend()) name = 'mine';
    if (!['recommend', 'mine'].includes(name)) return;
    state.activeTab = name;
    for (const tab of document.querySelectorAll('[data-tab]')) {
      const active = tab.dataset.tab === name;
      tab.setAttribute('aria-selected', String(active)); tab.tabIndex = active ? 0 : -1;
      $(`panel-${tab.dataset.tab}`).hidden = !active;
      if (active && focus) tab.focus();
    }
    if (name === 'mine') {
      for (const channel of ['clubs', 'players']) { cancelChannel(channel); clearDebounce(channel); }
      $('club-choice').setAttribute('aria-busy', 'false'); $('player-choice').setAttribute('aria-busy', 'false');
      $('clubs-more').disabled = manualClub(); $('players-more').disabled = false;
      if (!state.list.loaded) loadList();
      if (!state.dashboard.loaded) loadDashboard();
    } else {
      cancelChannel('list'); clearDebounce('list-query'); cancelChannel('dashboard');
      $('mine-list').setAttribute('aria-busy', 'false'); $('dashboard-metrics').setAttribute('aria-busy', 'false');
      $('mine-refresh').disabled = false; $('mine-more').disabled = false;
      if (!manualClub() && !state.selectedClub) loadClubs();
      if ($('player-lookup').open) loadPlayers();
    }
  }

  function clearPlayer(clearCategory = false) {
    const referenced = state.referenceRecommendation;
    const previous = referenced ? { age: $('player-age').value, position: $('player-position').value, sector: $('player-sector').value } : null;
    cancelChannel('players'); clearDebounce('players');
    if (!referenced) clearAutoPlayerProfile();
    state.selectedPlayer = null; state.players.clear(); state.playersCursor = null;
    $('player-choice').replaceChildren(option('', 'Seleccioná una categoría', true));
    $('players-more').hidden = true;
    $('player-query').value = '';
    $('player-first-name').value = ''; $('player-last-name').value = '';
    $('player-age').value = ''; state.playerAutoAge = null;
    $('player-position').value = ''; $('player-sector').value = 'no_especificado';
    if (referenced) {
      $('player-first-name').value = referenced.firstName; $('player-last-name').value = referenced.lastName;
      $('player-age').value = previous.age; $('player-position').value = previous.position; $('player-sector').value = previous.sector;
    }
    if (clearCategory) { $('player-category').value = ''; $('custom-category').value = ''; updateCustomCategory(); }
    updateSector(); updatePlayerLookup();
  }

  function clearClub() {
    const competition = state.clubAutoCompetition && route() === 'province' ? '' : $('club-competition').value;
    state.clubAutoCompetition = false;
    state.selectedClub = null;
    updateClubReference();
    restoreCompetitions(competition);
    $('selected-club').hidden = true;
    $('club-choice').value = '';
    clearPlayer(true);
  }

  function restoreCompetitions(value = '') {
    const competitions = (Array.isArray(state.bootstrap?.competitions) ? state.bootstrap.competitions : []).map((entry) => ({ value: entry.id, label: `${entry.name}${entry.season ? ` · ${entry.season}` : ''}` }));
    replaceOptions($('club-competition'), competitions, route() === 'province' ? 'Todas las competencias' : 'Seleccioná una competencia');
    $('club-competition').value = value;
    $('club-competition').disabled = manualClub();
    $('club-competition').required = route() === 'competition' && !manualClub();
    $('competition-required').hidden = route() === 'province';
  }

  function setManualClub(clear = true) {
    const manual = manualClub();
    cancelChannel('clubs'); clearDebounce('clubs');
    if (clear) clearClub();
    $('catalogue-fields').hidden = manual;
    $('manual-club-fields').hidden = !manual;
    for (const id of ['manual-province', 'manual-city', 'manual-club-name', 'manual-league']) {
      $(id).disabled = !manual; $(id).required = manual;
    }
    for (const id of ['club-province', 'club-competition', 'club-query', 'club-choice', 'clubs-more']) $(id).disabled = manual;
    $('club-province').required = !manual && route() === 'province';
    $('club-competition').required = !manual && route() === 'competition';
    if (manual && !$('manual-province').value) $('manual-province').value = $('club-province').value;
    updatePlayerLookup();
    if (!manual) loadClubs();
  }

  function updateRoute(clear = true) {
    const byProvince = route() === 'province';
    const flow = $('club-filter-flow');
    if (clear) {
      $('club-province').value = ''; $('club-competition').value = ''; $('club-query').value = '';
      clearClub();
    }
    const order = byProvince ? ['province-field', 'club-picker-field', 'competition-field'] : ['competition-field', 'province-field', 'club-picker-field'];
    for (const id of order) flow.append($(id));
    $('province-required').hidden = !byProvince;
    $('competition-required').hidden = byProvince;
    $('club-province').required = byProvince && !manualClub();
    $('club-competition').required = !byProvince && !manualClub();
    $('club-province').options[0].textContent = byProvince ? 'Seleccioná una provincia' : 'Todas las provincias';
    $('club-competition').options[0].textContent = byProvince ? 'Todas las competencias' : 'Seleccioná una competencia';
    $('competition-help').textContent = byProvince ? 'La competencia del primer equipo se completa cuando está disponible. La categoría del jugador se elige por separado.' : 'Elegí la competencia para consultar sus equipos. La categoría del jugador se elige por separado.';
    if (!manualClub()) loadClubs();
  }

  function clubsPayload(cursor = null) {
    return { province: $('club-province').value || null, competition_id: $('club-competition').value || null, query: $('club-query').value.trim(), cursor };
  }

  async function loadClubs(more = false) {
    if (state.activeTab !== 'recommend' || !canRecommend()) return;
    if (!state.bootstrap || manualClub()) return;
    clearDebounce('clubs');
    const request = requestChannel('clubs');
    const selectedId = state.selectedClub?.id;
    if (!more) { state.clubs.clear(); state.clubsCursor = null; state.clubsQuery = clubsPayload(); }
    const prerequisites = route() === 'province' ? $('club-province').value : $('club-competition').value;
    if (!prerequisites) {
      $('club-choice').replaceChildren(option('', route() === 'province' ? 'Elegí una provincia para buscar' : 'Elegí una competencia para buscar', true));
      $('clubs-help').textContent = 'Podés usar Otro club si no lo encontrás.';
      $('clubs-more').hidden = true; return;
    }
    if (!more) $('club-choice').replaceChildren(option('', 'Buscando clubes…', true));
    $('club-choice').setAttribute('aria-busy', 'true');
    $('clubs-more').disabled = true;
    $('clubs-help').textContent = more ? 'Cargando más clubes…' : 'Buscando clubes…';
    try {
      const data = await api('clubs', { ...(state.clubsQuery || clubsPayload()), cursor: more ? state.clubsCursor : null }, request.signal);
      if (!request.current()) return;
      for (const item of Array.isArray(data.items) ? data.items : []) state.clubs.set(String(item.id), item);
      state.clubsCursor = data.next_cursor || null;
      $('club-choice').replaceChildren(option('', state.clubs.size ? 'Seleccioná un equipo' : 'No encontramos clubes para estos filtros', true));
      for (const item of state.clubs.values()) {
        const label = [item.name, item.city, route() === 'province' ? item.competition_name : item.province].filter(Boolean).join(' · ');
        $('club-choice').append(option(item.id, label));
      }
      if (selectedId && state.clubs.has(String(selectedId))) $('club-choice').value = String(selectedId);
      $('clubs-help').textContent = state.clubs.size ? `${state.clubs.size} ${state.clubs.size === 1 ? 'club disponible' : 'clubes disponibles'}. Si falta uno, usá Otro club.` : 'Podés cargarlo manualmente con Otro club.';
      $('clubs-more').hidden = !state.clubsCursor;
      $('clubs-more').textContent = 'Cargar más clubes'; delete $('clubs-more').dataset.retry;
    } catch (error) {
      if (!request.current() || cancelled(error)) return;
      if (!more) $('club-choice').replaceChildren(option('', 'No se pudieron cargar los clubes', true));
      $('clubs-help').textContent = `${message(error)} También podés usar Otro club.`;
      $('clubs-more').hidden = false;
      $('clubs-more').textContent = 'Reintentar búsqueda';
      $('clubs-more').dataset.retry = 'true';
    } finally {
      if (request.current()) { $('club-choice').setAttribute('aria-busy', 'false'); $('clubs-more').disabled = false; }
    }
  }

  function selectClub() {
    const club = state.clubs.get($('club-choice').value);
    clearPlayer(true);
    if (route() === 'province') restoreCompetitions();
    state.clubAutoCompetition = false;
    state.selectedClub = club ? { ...club } : null;
    $('selected-club').hidden = !club;
    if (!club) return;
    const memberships = Array.isArray(club.competitions) ? club.competitions : [];
    if (route() === 'province' && memberships.length) {
      replaceOptions($('club-competition'), memberships.map((entry) => ({ value: entry.id, label: `${entry.name}${entry.season ? ` · ${entry.season}` : ''}` })), 'Seleccioná una competencia del club');
      $('club-competition').required = true; $('competition-required').hidden = false;
      state.clubAutoCompetition = true;
      $('club-competition').value = memberships.length === 1 ? String(memberships[0].id) : '';
      if (memberships.length === 1) applyClubCompetition(memberships[0]);
      else { state.selectedClub.competition_id = null; state.selectedClub.competition_name = null; }
    } else if (club.competition_id && [...$('club-competition').options].some((entry) => entry.value === String(club.competition_id))) {
      $('club-competition').value = String(club.competition_id); state.clubAutoCompetition = route() === 'province';
    } else if (route() === 'province') {
      $('club-competition').replaceChildren(option('', club.league || 'Sin competencia catalogada'));
      $('club-competition').disabled = true; $('club-competition').required = false;
      $('competition-required').hidden = true;
    }
    showClubSummary();
    updatePlayerLookup();
  }

  function applyClubCompetition(membership) {
    if (!state.selectedClub || !membership) return;
    state.selectedClub = { ...state.selectedClub, competition_id: membership.id, competition_name: membership.name, division: membership.division, reference_scope: membership.reference_scope, season: membership.season };
  }

  function showClubSummary() {
    const club = state.selectedClub;
    updateClubReference();
    if (!club) return;
    $('selected-club-name').textContent = club.name;
    const scope = club.reference_scope === 'primer_equipo_masculino' ? 'Referencia: primer equipo masculino' : '';
    $('selected-club-description').textContent = [club.city, club.province, club.competition_name || club.league, club.division, scope].filter(Boolean).join(' · ');
  }

  function updateClubReference() {
    const sources = Array.isArray(state.selectedClub?.source_urls) ? state.selectedClub.source_urls : [];
    const href = sources.map((raw) => safeUrl(raw, 'transfermarkt')).find((url) => url && /\/(?:startseite|kader)\/verein\/\d+(?:\/|$)/.test(new URL(url).pathname));
    const link = $('selected-club-transfermarkt');
    link.hidden = !href;
    if (href) link.href = href;
    else link.removeAttribute('href');
  }

  function updatePlayerReview() {
    const checkedAt = state.selectedPlayer?.checked_at;
    const parsed = checkedAt ? new Date(checkedAt) : null;
    const valid = parsed && !Number.isNaN(parsed.getTime());
    const review = $('selected-player-review');
    review.hidden = !valid;
    review.textContent = valid ? `Ficha de este jugador revisada el ${new Intl.DateTimeFormat('es-AR', { dateStyle: 'medium', timeZone: 'America/Argentina/Buenos_Aires' }).format(parsed)}.` : '';
  }

  function updateCustomCategory() {
    const custom = $('player-category').value === OTHER_CATEGORY;
    $('custom-category-field').hidden = !custom;
    $('custom-category').disabled = !custom;
    $('custom-category').required = custom;
  }

  function updatePlayerLookup() {
    const available = !state.referenceRecommendation && !manualClub() && Boolean(state.selectedClub) && Number(state.bootstrap?.catalogue?.player_count || 0) > 0;
    $('player-lookup').hidden = !available;
    if (!available) $('player-lookup').open = false;
    $('player-manual-help').textContent = state.referenceRecommendation ? 'La identidad está vinculada al aporte original. Para recomendar a otra persona, elegí Nuevo jugador. La posición y la edad que informes corresponden a tu nuevo aporte.' : state.selectedPlayer ? 'Datos del jugador seleccionado. Podés completar la posición que observaste.' : 'Completá los datos del jugador. No necesita figurar en el catálogo.';
    updatePlayerReview();
  }

  function updateReferenceNotice() {
    const reference = state.referenceRecommendation;
    $('reference-notice').hidden = !reference;
    $('reference-player-name').textContent = reference ? [reference.firstName, reference.lastName].filter(Boolean).join(' ') : '';
    $('reference-description').textContent = reference ? `Vinculado a ${reference.code || 'la recomendación original'}. Revisá el club y la categoría de este aporte y escribí tu propio motivo. El vínculo identifica a la persona, sin verificar por sí solo una referencia manual.` : '';
    $('player-first-name').readOnly = Boolean(reference); $('player-last-name').readOnly = Boolean(reference);
  }

  function clearRecommendationReference(resetPlayer = true) {
    state.referenceRecommendation = null;
    updateReferenceNotice();
    if (resetPlayer) clearPlayer(false);
    else updatePlayerLookup();
  }

  function updateSector() {
    const relevant = ['Lateral', 'Delantero Extremo'].includes($('player-position').value);
    $('sector-field').hidden = !relevant; $('player-sector').disabled = !relevant;
    if (!relevant) $('player-sector').value = 'no_especificado';
  }

  async function loadPlayers(more = false) {
    if (state.activeTab !== 'recommend' || !canRecommend() || !state.selectedClub || manualClub() || $('player-lookup').hidden) return;
    clearDebounce('players');
    const request = requestChannel('players');
    if (!more) {
      state.players.clear(); state.playersCursor = null;
      state.playersQuery = { club_id: state.selectedClub.id, category: category(), query: $('player-query').value.trim() };
    }
    if (!category() || category().length < 2) {
      $('player-choice').replaceChildren(option('', 'Seleccioná una categoría para buscar', true));
      $('players-help').textContent = 'También podés completar nombre y apellido manualmente.';
      $('players-more').hidden = true; return;
    }
    const selectedId = state.selectedPlayer?.id;
    if (!more) $('player-choice').replaceChildren(option('', 'Buscando jugadores…', true));
    $('player-choice').setAttribute('aria-busy', 'true'); $('players-more').disabled = true;
    $('players-help').textContent = 'Buscando jugadores…';
    try {
      const data = await api('players', { ...state.playersQuery, cursor: more ? state.playersCursor : null }, request.signal);
      if (!request.current()) return;
      for (const player of Array.isArray(data.items) ? data.items : []) state.players.set(String(player.id), player);
      state.playersCursor = data.next_cursor || null;
      $('player-choice').replaceChildren(option('', state.players.size ? 'Seleccioná un jugador' : 'No encontramos jugadores para esta búsqueda', true));
      for (const player of state.players.values()) $('player-choice').append(option(player.id, [player.first_name, player.last_name].filter(Boolean).join(' ') + (player.position ? ` · ${player.position}` : '')));
      if (selectedId && state.players.has(String(selectedId))) $('player-choice').value = String(selectedId);
      $('players-help').textContent = state.players.size ? `${state.players.size} ${state.players.size === 1 ? 'jugador disponible' : 'jugadores disponibles'}. También podés cargar otro manualmente.` : 'Completá nombre y apellido en los campos de abajo.';
      $('players-more').hidden = !state.playersCursor;
      $('players-more').textContent = 'Cargar más jugadores'; delete $('players-more').dataset.retry;
    } catch (error) {
      if (!request.current() || cancelled(error)) return;
      if (!more) $('player-choice').replaceChildren(option('', 'No se pudo cargar el catálogo de jugadores', true));
      $('players-help').textContent = `${message(error)} Podés completar el jugador manualmente.`;
      $('players-more').hidden = false; $('players-more').textContent = 'Reintentar búsqueda'; $('players-more').dataset.retry = 'true';
    } finally {
      if (request.current()) { $('player-choice').setAttribute('aria-busy', 'false'); $('players-more').disabled = false; }
    }
  }

  function selectPlayer() {
    if (state.referenceRecommendation) return;
    const player = state.players.get($('player-choice').value);
    if (!player) return;
    state.selectedPlayer = player;
    $('player-first-name').value = player.first_name || '';
    $('player-last-name').value = player.last_name || '';
    state.playerAutoAge = knownAge(player.age_current ?? player.age_at_recommendation);
    $('player-age').value = state.playerAutoAge === null ? '' : String(state.playerAutoAge);
    $('player-position').value = player.position || '';
    $('player-sector').value = 'no_especificado';
    autofillPlayerProfile(player);
    updateSector(); updatePlayerLookup();
  }

  function validateField(id, minimum, label) {
    const field = $(id);
    if (field.disabled) return true;
    if (field.value.trim().length < minimum) {
      field.setCustomValidity(`${label} debe tener al menos ${minimum} caracteres.`); field.reportValidity(); return false;
    }
    field.setCustomValidity(''); return true;
  }

  function createPayload() {
    if (!canRecommend()) return null;
    if (!$('recommend-form').reportValidity()) return null;
    if (!manualClub() && !state.selectedClub) {
      setFeedback('create-feedback', 'Seleccioná un equipo del listado o activá Otro club para ingresarlo manualmente.', 'error', true);
      return null;
    }
    const required = [['player-first-name', 2, 'El nombre'], ['player-last-name', 2, 'El apellido'], ['recommend-reason', 20, 'El motivo']];
    if (manualClub()) required.unshift(['manual-city', 2, 'La ciudad'], ['manual-club-name', 2, 'El nombre del club'], ['manual-league', 2, 'La liga']);
    if ($('player-category').value === OTHER_CATEGORY) required.push(['custom-category', 2, 'La categoría']);
    for (const [id, minimum, label] of required) if (!validateField(id, minimum, label)) return null;
    if (state.referenceRecommendation && ($('player-first-name').value.trim() !== state.referenceRecommendation.firstName || $('player-last-name').value.trim() !== state.referenceRecommendation.lastName)) {
      setFeedback('create-feedback', 'Para cambiar la persona vinculada, elegí Nuevo jugador y completá sus datos.', 'error', true); return null;
    }
    const ageInput = $('player-age');
    if (ageInput.value.trim() && knownAge(ageInput.value) === null) {
      ageInput.setCustomValidity('Ingresá una edad en años cumplidos, entre 1 y 100, o dejá el campo vacío.'); ageInput.reportValidity(); return null;
    }
    for (const [id, kind, description] of [
      ['video-url', 'video', 'Ingresá un enlace HTTPS de YouTube o Vimeo.'],
      ['transfermarkt-url', 'transfermarkt', 'Ingresá un enlace HTTPS al perfil de un jugador o al plantel de un club en Transfermarkt.']
    ]) {
      const input = $(id);
      if (input.value.trim() && !safeUrl(input.value.trim(), kind)) { input.setCustomValidity(description); input.reportValidity(); return null; }
    }
    state.createRequestId ||= uuid();
    return {
      request_id: state.createRequestId,
      panel_context: 'socio',
      reference_recommendation_id: state.referenceRecommendation?.id || null,
      club_id: manualClub() ? null : state.selectedClub.id,
      club_manual: manualClub() ? { province: $('manual-province').value, city: $('manual-city').value.trim(), name: $('manual-club-name').value.trim(), league: $('manual-league').value.trim() } : null,
      competition_id: manualClub() ? null : state.selectedClub.competition_id || $('club-competition').value || null,
      category: category(), player_id: state.referenceRecommendation ? null : state.selectedPlayer?.id || null,
      player: { first_name: $('player-first-name').value.trim(), last_name: $('player-last-name').value.trim(), position: $('player-position').value, sector: $('player-sector').disabled ? 'no_especificado' : $('player-sector').value, age_at_recommendation: knownAge(ageInput.value) },
      reason: $('recommend-reason').value.trim(), observation: $('recommend-observation').value.trim(),
      video_url: safeUrl($('video-url').value.trim(), 'video'), transfermarkt_url: safeUrl($('transfermarkt-url').value.trim(), 'transfermarkt')
    };
  }

  async function createRecommendation(event) {
    event.preventDefault();
    if (!canRecommend() || state.createBusy || state.expired) return;
    const generation = state.sessionGeneration;
    const payload = state.createPending || createPayload();
    if (!payload) return;
    state.createPending = payload; state.createBusy = true;
    $('create-fields').disabled = true; $('create-submit').disabled = true;
    $('create-submit').textContent = 'Enviando recomendación…';
    setFeedback('create-feedback', 'Estamos registrando tu aporte.', 'info');
    try {
      const data = await api('create', payload);
      const recommendation = data.recommendation;
      if (!recommendation?.id) throw new ApiError('No recibimos una constancia completa del envío. Reintentá para recuperar el resultado.', 'INVALID_RESPONSE', 502);
      state.createPending = null; state.createRequestId = null; state.successId = recommendation.id;
      state.list.loaded = false; state.dashboard.loaded = false;
      $('recommend-layout').hidden = true; $('create-success').hidden = false;
      const name = [recommendation.player?.first_name || payload.player.first_name, recommendation.player?.last_name || payload.player.last_name].join(' ');
      $('success-description').textContent = `${name}${recommendation.club?.name ? ` · ${recommendation.club.name}` : ''}. Referencia: ${recommendation.code || recommendation.id}.`;
      setFeedback('create-feedback', '');
      $('create-success').focus(); $('create-success').scrollIntoView({ block: 'start', behavior: 'smooth' });
    } catch (error) {
      if (cancelled(error)) return;
      if (uncertain(error)) {
        setFeedback('create-feedback', 'Todavía no pudimos confirmar el resultado. Reintentá el envío: recuperaremos o completaremos la misma recomendación, sin duplicarla.', 'info', true);
      } else {
        state.createPending = null;
        setFeedback('create-feedback', message(error), 'error', true);
      }
    } finally {
      if (generation === state.sessionGeneration) {
        state.createBusy = false;
        $('create-fields').disabled = Boolean(state.createPending);
        $('create-submit').disabled = !canRecommend();
        $('create-submit').textContent = state.createPending ? 'Reintentar envío' : 'Enviar recomendación ↗';
      }
    }
  }

  function newRecommendation(focus = true) {
    if (!canRecommend()) return;
    state.referenceRecommendation = null;
    $('recommend-form').reset();
    updateReferenceNotice();
    for (const input of $('recommend-form').querySelectorAll('input,select,textarea')) input.setCustomValidity('');
    state.createRequestId = null; state.createPending = null; state.successId = null;
    $('manual-club-toggle').checked = Number(state.bootstrap?.catalogue?.club_count || 0) === 0;
    $('create-success').hidden = true; $('recommend-layout').hidden = false;
    $('create-fields').disabled = false; $('reason-count').textContent = '0 / 4000';
    clearClub(); updateRoute(); setManualClub(false); updateCustomCategory();
    setFeedback('create-feedback', '');
    if (focus) {
      $('club-section-title').scrollIntoView({ block: 'start' });
      const target = manualClub() ? $('manual-province') : $('club-province'); target.focus();
    }
  }

  function recommendAlso(recommendation) {
    if (!canRecommend() || !recommendation?.id) return;
    if (state.createBusy || state.createPending) {
      if ($('detail-dialog').open) $('detail-dialog').close();
      activateTab('recommend');
      setFeedback('create-feedback', 'Primero confirmá el envío pendiente antes de iniciar otra recomendación.', 'info', true); return;
    }
    newRecommendation(false);
    state.referenceRecommendation = { id: recommendation.id, code: recommendation.code, firstName: (recommendation.player?.first_name || '').trim(), lastName: (recommendation.player?.last_name || '').trim() };
    const club = recommendation.club || {};
    const manual = !club.id || club.source === 'manual';
    $('manual-club-toggle').checked = manual; setManualClub(false);
    if (manual) {
      $('manual-province').value = club.province || ''; $('manual-city').value = club.city || '';
      $('manual-club-name').value = club.name || ''; $('manual-league').value = club.league || club.competition_name || '';
    } else {
      $('club-province').value = club.province || '';
      const referenceClub = { ...club, competitions: club.competition_id ? [{ id: club.competition_id, name: club.competition_name || club.league || 'Competencia del aporte original', season: club.season, division: club.division, reference_scope: club.reference_scope }] : [] };
      state.clubs.set(String(club.id), referenceClub);
      $('club-choice').replaceChildren(option(club.id, club.name || 'Equipo del aporte original'));
      $('club-choice').value = String(club.id); selectClub();
    }
    const existingCategory = recommendation.category || '';
    if ([...$('player-category').options].some((entry) => entry.value === existingCategory)) $('player-category').value = existingCategory;
    else { $('player-category').value = OTHER_CATEGORY; $('custom-category').value = existingCategory; }
    updateCustomCategory();
    $('player-first-name').value = state.referenceRecommendation.firstName; $('player-last-name').value = state.referenceRecommendation.lastName;
    $('player-age').value = ''; state.playerAutoAge = null;
    $('player-position').value = recommendation.player?.position || ''; $('player-sector').value = recommendation.player?.sector || 'no_especificado';
    autofillPlayerProfile({ transfermarkt_url: recommendation.transfermarkt_url });
    updateReferenceNotice(); updateSector(); updatePlayerLookup();
    if ($('detail-dialog').open) $('detail-dialog').close();
    activateTab('recommend', true);
    $('reference-notice').scrollIntoView({ block: 'start' }); $('recommend-reason').focus({ preventScroll: true });
  }

  function statusBadge(value) {
    const valid = Object.hasOwn(STATUS, value);
    return node('span', `status-badge${valid ? ` status-${value}` : ''}`, valid ? STATUS[value] : 'Estado no disponible');
  }

  function playerName(recommendation) {
    return [recommendation.player?.first_name, recommendation.player?.last_name].filter(Boolean).join(' ') || 'Jugador sin nombre informado';
  }

  function card(recommendation) {
    const article = node('article', 'recommendation-card');
    const content = node('div', 'card-content');
    content.append(node('h3', '', playerName(recommendation)));
    if (recommendation.category) content.append(node('p', 'card-category', recommendation.category));
    const facts = node('dl', 'record-grid');
    for (const [label, value] of [
      ['Fecha de recomendación', date(recommendation.created_at)],
      ['Socio que recomienda', authorLabel(recommendation.author)],
      ['Club', recommendation.club?.name],
      ['Liga / competencia', recommendation.club?.competition_name || recommendation.club?.league],
      ['Provincia / CABA', recommendation.club?.province],
      ['Edad al recomendar', ageLabel(recommendation.player)],
      ['Posición', recommendation.player?.position]
    ]) facts.append(detailPair(label, value));
    const market = node('div', 'record-market');
    const marketValue = node('dd'); appendMarketValue(marketValue, recommendation.player?.market_value);
    market.append(node('dt', '', 'Valor de mercado'), marketValue); facts.append(market);
    content.append(facts);
    const actions = node('div', 'card-actions');
    actions.append(statusBadge(recommendation.status));
    const button = node('button', 'button button-secondary', 'Ver detalle'); button.type = 'button';
    button.setAttribute('aria-label', `Ver recomendación de ${playerName(recommendation)}`);
    button.addEventListener('click', () => openDetail(recommendation.id));
    actions.append(button);
    if (recommendation.code) actions.append(node('span', 'card-reference', recommendation.code));
    article.append(content, actions); return article;
  }

  function renderList() {
    const list = $('mine-list'); list.replaceChildren();
    const items = state.list.items;
    if (!items.length) {
      const empty = node('div', 'empty-state');
      const filtered = Boolean($('mine-status').value || $('mine-query').value.trim() || state.rankedPlayerFilter);
      empty.append(node('h3', '', filtered ? 'No hay recomendaciones con estos filtros' : $('mine-only').checked ? 'Todavía no enviaste recomendaciones' : 'Todavía no hay recomendaciones del club'));
      empty.append(node('p', '', filtered ? 'Probá con otro estado o modificá la búsqueda.' : 'Los aportes de los socios aparecerán aquí, con su autor, sus datos y su seguimiento.'));
      if (canRecommend() && !filtered) {
        const button = node('button', 'button button-primary', 'Recomendar jugador'); button.type = 'button';
        button.addEventListener('click', () => activateTab('recommend', true)); empty.append(button);
      }
      list.append(empty);
    } else for (const item of items) list.append(card(item));
    $('mine-count').textContent = items.length ? `${items.length} ${items.length === 1 ? 'recomendación cargada' : 'recomendaciones cargadas'}` : '';
  }

  async function loadList(more = false) {
    if (!state.actor || state.expired || state.activeTab !== 'mine' || more && !state.list.cursor) return;
    clearDebounce('list-query');
    const request = requestChannel('list');
    const listState = state.list;
    const list = $('mine-list');
    const moreButton = $('mine-more');
    if (!more) {
      listState.items = []; listState.cursor = null; listState.loaded = false;
      listState.query = { status: $('mine-status').value || null, query: $('mine-query').value.trim(), mine_only: $('mine-only').checked, player_id: state.rankedPlayerFilter?.playerId || null, reference_recommendation_id: state.rankedPlayerFilter?.referenceRecommendationId || null };
      const loading = node('div', 'list-loading');
      const ring = node('span', 'loading-ring'); ring.setAttribute('aria-hidden', 'true');
      loading.append(ring, node('span', '', 'Cargando recomendaciones…')); list.replaceChildren(loading);
      $('mine-count').textContent = ''; moreButton.hidden = true;
    }
    list.setAttribute('aria-busy', 'true'); moreButton.disabled = true;
    $('mine-refresh').disabled = true;
    setFeedback('mine-feedback', '');
    try {
      const payload = { ...listState.query, cursor: more ? listState.cursor : null };
      const data = await api('feed', payload, request.signal);
      if (!request.current()) return;
      const existing = new Map(listState.items.map((item) => [String(item.id), item]));
      for (const item of Array.isArray(data.items) ? data.items : []) existing.set(String(item.id), item);
      listState.items = [...existing.values()]; listState.cursor = data.next_cursor || null; listState.loaded = true;
      renderList(); moreButton.hidden = !listState.cursor;
    } catch (error) {
      if (!request.current() || cancelled(error)) return;
      if (!more) list.replaceChildren();
      setFeedback('mine-feedback', `${message(error)} Usá Actualizar para volver a intentar.`);
    } finally {
      if (request.current()) { list.setAttribute('aria-busy', 'false'); moreButton.disabled = false; $('mine-refresh').disabled = false; }
    }
  }

  function renderDashboard(dashboard) {
    for (const [id, key] of Object.entries(DASHBOARD_METRICS)) $(id).textContent = Number(dashboard[key]).toLocaleString('es-AR');
    const total = dashboard.total_recommendations.toLocaleString('es-AR');
    const identified = dashboard.identified_players.toLocaleString('es-AR');
    const unverified = dashboard.unverified_player_references.toLocaleString('es-AR');
    $('dashboard-total').textContent = `${total} ${dashboard.total_recommendations === 1 ? 'recomendación registrada' : 'recomendaciones registradas'} · ${identified} ${dashboard.identified_players === 1 ? 'jugador identificado en el catálogo' : 'jugadores identificados en el catálogo'} · ${unverified} ${dashboard.unverified_player_references === 1 ? 'referencia sin identidad comprobada' : 'referencias sin identidad comprobada'}.`;
    $('dashboard-updated').hidden = !shortDate(dashboard.as_of);
    $('dashboard-updated').textContent = shortDate(dashboard.as_of) ? `Última consulta: ${date(dashboard.as_of)}.` : '';
    renderRanking(dashboard.most_recommended_players);
  }

  function renderRanking(entries) {
    const rows = (Array.isArray(entries) ? entries : [])
      .filter((entry) => ['catalogue', 'member_reference'].includes(entry.identity_type) && (typeof entry.reference_recommendation_id === 'string' && entry.reference_recommendation_id || entry.identity_type === 'catalogue' && typeof entry.player_id === 'string' && entry.player_id) && Number.isSafeInteger(entry.recommendation_count) && entry.recommendation_count >= 2)
      .sort((a, b) => b.recommendation_count - a.recommendation_count).slice(0, 10);
    const list = $('ranking-list'); list.replaceChildren(); list.hidden = rows.length === 0;
    $('ranking-empty').hidden = rows.length > 0;
    $('ranking-empty').textContent = Array.isArray(entries) ? 'Todavía no hay jugadores con dos o más recomendaciones vinculadas a la misma referencia.' : 'El ranking no está disponible en esta consulta. Podés reintentar con Actualizar.';
    for (const entry of rows) {
      const item = node('li', 'ranking-item');
      const identity = node('div');
      const name = playerName(entry);
      identity.append(node('p', 'ranking-name', name));
      if (entry.club?.name) identity.append(node('p', 'ranking-club', `Club en el último aporte: ${entry.club.name}`));
      identity.append(node('p', 'ranking-identity', entry.identity_type === 'member_reference' ? 'Identidad declarada por socios' : 'Identificado en el catálogo'));
      const count = node('div', 'ranking-count');
      count.append(node('strong', '', entry.recommendation_count.toLocaleString('es-AR')), node('span', '', 'recomendaciones'));
      const button = node('button', 'button button-small button-secondary', 'Ver recomendaciones'); button.type = 'button';
      button.setAttribute('aria-label', `Ver las ${entry.recommendation_count} recomendaciones de ${name}`);
      button.addEventListener('click', () => showPlayerRecommendations(entry.reference_recommendation_id, entry.identity_type === 'catalogue' ? entry.player_id : null, name));
      item.append(identity, count, button); list.append(item);
    }
  }

  function showPlayerRecommendations(referenceRecommendationId, playerId, name) {
    if (!referenceRecommendationId && !playerId) return;
    state.rankedPlayerFilter = { referenceRecommendationId: referenceRecommendationId || null, playerId: referenceRecommendationId ? null : playerId, name };
    $('player-filter-name').textContent = name; $('player-filter').hidden = false;
    $('mine-status').value = ''; $('mine-query').value = ''; $('mine-only').checked = false;
    state.list.loaded = false;
    if ($('detail-dialog').open) $('detail-dialog').close();
    activateTab('mine');
    $('recommendations-title').scrollIntoView({ block: 'start' }); $('recommendations-title').focus({ preventScroll: true });
  }

  async function loadDashboard() {
    if (!state.actor || state.expired || state.activeTab !== 'mine') return;
    const request = requestChannel('dashboard');
    state.dashboard.loaded = false;
    $('dashboard-metrics').setAttribute('aria-busy', 'true');
    setFeedback('dashboard-feedback', '');
    try {
      const data = await api('dashboard', {}, request.signal);
      if (!request.current()) return;
      const dashboard = data.dashboard;
      const keys = [...Object.values(DASHBOARD_METRICS), 'total_recommendations', 'identified_players', 'unverified_player_references'];
      if (!dashboard || dashboard.scope !== 'all_recommendations' || dashboard.milestone_unit !== 'player_references' || keys.some((key) => !Number.isSafeInteger(dashboard[key]) || dashboard[key] < 0)) {
        throw new ApiError('No recibimos totales globales completos. Podés reintentar con Actualizar.', 'INVALID_DASHBOARD', 502);
      }
      state.dashboard.data = dashboard; state.dashboard.loaded = true;
      renderDashboard(dashboard);
    } catch (error) {
      if (!request.current() || cancelled(error)) return;
      setFeedback('dashboard-feedback', `${message(error)}${state.dashboard.data ? ' Los totales visibles corresponden a la consulta anterior.' : ' El listado puede consultarse mientras tanto.'}`);
      if (!state.dashboard.data) {
        $('dashboard-total').textContent = 'Los totales globales no están disponibles. Usá Actualizar para volver a consultar.';
        $('ranking-empty').textContent = 'No pudimos consultar el ranking. Usá Actualizar para volver a intentar.';
      }
    } finally {
      if (request.current()) $('dashboard-metrics').setAttribute('aria-busy', 'false');
    }
  }

  function refreshOverview() {
    loadList(); loadDashboard();
  }

  function detailPair(label, value) {
    const group = node('div'); group.append(node('dt', '', label), node('dd', '', value || 'No informado')); return group;
  }

  function textSection(title, text) {
    const section = node('section', 'detail-section'); section.append(node('h3', '', title), node('p', '', text || 'Sin información adicional.')); return section;
  }

  function renderProof(proof, initial = true) {
    const details = node('details', 'proof-panel'); details.append(node('summary', '', initial ? 'Registro criptográfico y blockchain · recomendación inicial' : 'Registro criptográfico y blockchain · esta actuación'));
    const content = node('div', 'proof-content');
    const recognised = proof && Object.hasOwn(PROOF_STATUS, proof.status);
    content.append(node('p', '', recognised ? PROOF_STATUS[proof.status] : 'No hay una constancia de anclaje disponible para mostrar.'));
    if (proof?.status === 'registrada') content.append(node('p', '', 'El aporte tiene un registro de auditoría. Su anclaje en blockchain todavía no está confirmado.'));
    else if (proof?.status === 'preparada') content.append(node('p', '', 'El registro está preparado para su anclaje. Todavía no hay confirmación en blockchain.'));
    else if (proof?.status === 'enviada') content.append(node('p', '', 'El anclaje fue enviado y está pendiente de confirmación.'));
    const metadata = node('dl');
    for (const [label, value] of [[initial ? 'Huella del registro inicial' : 'Huella de esta actuación', proof?.commitment_hash], ['Registro de auditoría', proof?.audit_event_id], ['Huella en auditoría general', proof?.audit_event_hash], ['Lote', proof?.lot_id], ['Raíz Merkle', proof?.merkle_root], ['Transacción', proof?.transaction_hash], ['Bloque confirmado', proof?.status === 'anclada' ? proof?.block_number : null]]) {
      if (value === null || value === undefined || value === '') continue;
      const entry = node('div'); entry.append(node('dt', '', label), node('dd', '', value)); metadata.append(entry);
    }
    if (metadata.childElementCount) content.append(metadata);
    if (proof?.transaction_hash && /^0x[0-9a-fA-F]{64}$/.test(proof.transaction_hash) && [137, 80002].includes(Number(proof.chain_id))) {
      const links = node('div', 'detail-links');
      appendLink(links, `https://${Number(proof.chain_id) === 137 ? 'polygonscan.com' : 'amoy.polygonscan.com'}/tx/${proof.transaction_hash}`, 'Consultar transacción', 'explorer');
      content.append(links);
    }
    details.append(content); return details;
  }

  function eventTitle(event) {
    const previous = STATUS[event.previous_status];
    const current = STATUS[event.new_status || event.status];
    if (previous && current && event.previous_status !== (event.new_status || event.status)) return `${previous} → ${current}`;
    if (/club_validated|club_validado/.test(event.type || '')) return 'Club validado para el catálogo';
    if (/created|cread|recibida/.test(event.type || '')) return 'Recomendación recibida';
    if (/info|aporte/.test(event.type || '') && !/solicit/.test(event.type || '')) return 'Información agregada';
    return current || 'Actualización de la recomendación';
  }

  function renderEventProof(event) {
    if (typeof event.id !== 'string' || !event.id) return null;
    const container = node('div', 'event-proof');
    const button = node('button', 'button button-small button-subtle', 'Ver constancia de esta actuación'); button.type = 'button';
    const feedback = node('div', 'feedback'); feedback.hidden = true; feedback.setAttribute('role', 'alert');
    const output = node('div', 'event-proof-output');
    const detailId = state.currentDetailId;
    button.addEventListener('click', async () => {
      if (button.disabled || !container.isConnected || !$('detail-dialog').open || state.currentDetailId !== detailId) return;
      const request = requestChannel(`event-proof:${event.id}`);
      button.disabled = true; button.textContent = 'Consultando constancia…'; setFeedback(feedback, '');
      try {
        const data = await api('event_proof', { event_id: event.id }, request.signal);
        if (!request.current() || !container.isConnected || !$('detail-dialog').open || state.currentDetailId !== detailId) return;
        if (data.event_id !== event.id || !data.proof) throw new ApiError('No recibimos la constancia de esta actuación. Podés reintentar.', 'INVALID_RESPONSE', 502);
        const proof = renderProof(data.proof, false); proof.open = true;
        output.replaceChildren(proof); button.hidden = true;
      } catch (error) {
        if (!request.current() || cancelled(error) || !container.isConnected || !$('detail-dialog').open) return;
        setFeedback(feedback, message(error));
      } finally {
        if (request.current()) { button.disabled = false; button.textContent = 'Ver constancia de esta actuación'; }
      }
    });
    container.append(button, feedback, output); return container;
  }

  function renderEvents(events) {
    const section = node('section', 'detail-section'); section.append(node('h3', '', 'Historial de seguimiento'));
    const rows = (Array.isArray(events) ? [...events] : []).sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
    if (!rows.length) { section.append(node('p', '', 'Todavía no hay novedades de seguimiento.')); return section; }
    const timeline = node('ol', 'timeline');
    for (const event of rows) {
      const item = node('li');
      item.append(node('div', 'timeline-heading', eventTitle(event)));
      const actor = event.actor || { name: event.actor_name || (event.actor_role === 'admin' ? 'Equipo evaluador' : 'Socio de Club Abierto'), numero_socio: event.actor_numero_socio, role: event.actor_role };
      item.append(node('div', 'timeline-meta', `${date(event.created_at)} · ${authorLabel(actor)}${actor.role === 'admin' ? ' · Equipo evaluador' : ''}`));
      if (event.message) item.append(node('p', 'timeline-message', event.message));
      const proof = renderEventProof(event); if (proof) item.append(proof);
      timeline.append(item);
    }
    section.append(timeline); return section;
  }

  function formField(label, id, type, options = {}) {
    const field = node('div', 'field'); const labelNode = node('label', '', label); labelNode.htmlFor = id;
    const input = document.createElement(type); input.id = id;
    for (const [key, value] of Object.entries(options)) input[key] = value;
    input.addEventListener('input', () => input.setCustomValidity(''));
    field.append(labelNode, input); return { field, input };
  }

  function renderActionForm(recommendation, admin, validateClub = false) {
    const action = validateClub ? 'admin_validate_club' : admin ? 'admin_update' : 'add_info';
    const actionLabel = validateClub ? 'Validar club' : admin ? 'Guardar seguimiento' : 'Agregar información';
    const mutationKey = `${action}:${recommendation.id}`;
    const form = node('form', 'detail-form'); form.autocomplete = 'off';
    form.append(node('h3', '', validateClub ? 'Validar club para el catálogo' : admin ? 'Actualizar seguimiento' : 'Agregar información'));
    form.append(node('p', 'muted', validateClub ? 'Confirmá la revisión del club. El motivo quedará visible en el historial y la recomendación conservará los datos originales.' : admin ? 'La devolución quedará visible para todos los socios.' : 'Sumá una observación o un dato a tu recomendación. Será visible para todos los socios.'));
    const fields = node('fieldset');
    const legend = node('legend', 'sr-only', admin ? 'Actualización de la recomendación' : 'Información adicional'); fields.append(legend);
    let statusInput;
    if (admin && !validateClub) {
      const statusField = formField('Estado', `${action}-status`, 'select', { required: true }); statusInput = statusField.input;
      for (const [value, label] of Object.entries(STATUS)) statusInput.append(option(value, label));
      statusInput.value = recommendation.status; fields.append(statusField.field);
    }
    const messageField = formField(validateClub ? 'Motivo de validación *' : admin ? 'Devolución para los socios *' : 'Información adicional *', `${action}-message`, 'textarea', { required: true, minLength: 2, maxLength: 4000, rows: 4 });
    fields.append(messageField.field);
    const button = node('button', 'button button-primary', actionLabel); button.type = 'submit';
    const feedback = node('div', 'feedback'); feedback.hidden = true; feedback.tabIndex = -1; feedback.setAttribute('role', 'alert');
    form.append(fields, button, feedback);
    const pending = state.mutations.get(mutationKey);
    if (pending?.payload) {
      messageField.input.value = pending.payload.message;
      if (statusInput) statusInput.value = pending.payload.status;
      fields.disabled = true; button.textContent = pending.busy ? 'Guardando…' : 'Reintentar actualización'; button.disabled = pending.busy;
      setFeedback(feedback, pending.busy ? 'Estamos registrando esta actualización.' : 'La actualización está pendiente de confirmar. Reintentá para recuperar el mismo envío.', 'info');
    }
    form.addEventListener('submit', async (event) => {
      event.preventDefault();
      const previous = state.mutations.get(mutationKey);
      if (previous?.busy || state.expired || (admin ? !canManage(recommendation) : recommendation.can_add_info !== true)) return;
      if (!previous?.payload && messageField.input.value.trim().length < 2) {
        messageField.input.setCustomValidity('Escribí al menos 2 caracteres.'); messageField.input.reportValidity(); return;
      }
      const payload = previous?.payload || {
        id: recommendation.id, request_id: previous?.requestId || uuid(), message: messageField.input.value.trim(),
        ...(admin && !validateClub ? { status: statusInput.value } : {})
      };
      state.mutations.set(mutationKey, { requestId: payload.request_id, payload, busy: true });
      fields.disabled = true; button.disabled = true; button.textContent = 'Guardando…';
      setFeedback(feedback, 'Estamos registrando la actualización.', 'info');
      try {
        await api(action, payload);
        state.mutations.delete(mutationKey);
        state.list.loaded = false; state.dashboard.loaded = false;
        if (state.activeTab === 'mine') refreshOverview();
        if ($('detail-dialog').open && state.currentDetailId === recommendation.id) await openDetail(recommendation.id, validateClub ? 'Club validado. La constancia ya está disponible en el historial.' : admin ? 'Seguimiento actualizado.' : 'Información agregada al historial.');
      } catch (error) {
        if (cancelled(error)) return;
        if (uncertain(error)) {
          state.mutations.set(mutationKey, { requestId: payload.request_id, payload, busy: false });
          setFeedback(feedback, 'No recibimos confirmación. Reintentá para recuperar o completar esta misma actualización, sin duplicarla.', 'info', true);
          button.textContent = 'Reintentar actualización';
        } else {
          state.mutations.set(mutationKey, { requestId: payload.request_id, payload: null, busy: false });
          fields.disabled = false; button.textContent = actionLabel;
          setFeedback(feedback, message(error), 'error', true);
        }
        if (!form.isConnected && $('detail-dialog').open && state.currentDetailId === recommendation.id) {
          const current = $('detail-body').querySelector(`form[data-mutation="${action}"]`);
          if (current) {
            const replacement = renderActionForm(recommendation, admin, validateClub); current.replaceWith(replacement);
            if (!uncertain(error)) setFeedback(replacement.querySelector('.feedback'), message(error), 'error');
          }
        }
      } finally { button.disabled = false; }
    });
    form.dataset.mutation = action;
    return form;
  }

  async function openDetail(id, successMessage = '') {
    if (!id || state.expired) return;
    for (const [key] of channels) if (key.startsWith('event-proof:')) cancelChannel(key);
    state.currentDetailId = id;
    const dialog = $('detail-dialog');
    $('detail-code').textContent = 'RECOMENDACIÓN'; $('detail-title').textContent = 'Cargando detalle';
    const loading = node('div', 'list-loading');
    const ring = node('span', 'loading-ring'); ring.setAttribute('aria-hidden', 'true');
    loading.append(ring, node('span', '', 'Consultando recomendación…')); $('detail-body').replaceChildren(loading);
    if (!dialog.open) dialog.showModal();
    $('detail-title').focus();
    const request = requestChannel('detail');
    try {
      const data = await api('detail', { id }, request.signal);
      if (!request.current() || !dialog.open || state.currentDetailId !== id) return;
      const recommendation = data.recommendation;
      if (!recommendation?.id) throw new ApiError('No encontramos esta recomendación.', 'NOT_FOUND', 404);
      $('detail-title').textContent = playerName(recommendation);
      $('detail-code').textContent = recommendation.code || 'RECOMENDACIÓN';
      const body = $('detail-body'); body.replaceChildren();
      if (successMessage) { const feedback = node('div', 'feedback feedback-success', successMessage); feedback.setAttribute('role', 'status'); body.append(feedback); }
      const statusRow = node('div', 'detail-status-row'); statusRow.append(statusBadge(recommendation.status), node('span', '', `Enviada el ${date(recommendation.created_at)}`)); body.append(statusRow);
      const grid = node('dl', 'detail-grid');
      for (const [label, value] of [
        ['Club', recommendation.club?.name], ['Ubicación', [recommendation.club?.city, recommendation.club?.province].filter(Boolean).join(' · ')],
        [recommendation.club?.reference_scope === 'primer_equipo_masculino' ? 'Competencia de referencia · primer equipo masculino' : 'Liga / competencia del club', recommendation.club?.competition_name || recommendation.club?.league], ['Categoría del jugador', recommendation.category],
        ['Edad al recomendar', ageLabel(recommendation.player)], ['Posición', recommendation.player?.position], ['Sector', { derecha: 'Derecha', izquierda: 'Izquierda', ambos: 'Ambos', no_especificado: 'Sin especificar' }[recommendation.player?.sector] || 'Sin especificar']
      ]) grid.append(detailPair(label, value));
      grid.prepend(detailPair('Socio que recomienda', authorLabel(recommendation.author)));
      const market = node('div', 'detail-market');
      const marketValue = node('dd'); appendMarketValue(marketValue, recommendation.player?.market_value);
      market.append(node('dt', '', 'Valor de mercado'), marketValue); grid.append(market);
      body.append(grid, textSection('Motivo de la recomendación', recommendation.reason));
      if (recommendation.observation) body.append(textSection('Contexto de la observación', recommendation.observation));
      if (recommendation.video_url || recommendation.transfermarkt_url) {
        const links = node('div', 'detail-links'); appendLink(links, recommendation.video_url, 'Ver video', 'video'); appendLink(links, recommendation.transfermarkt_url, 'Consultar Transfermarkt', 'transfermarkt');
        if (links.childElementCount) body.append(links);
      }
      const playerActions = node('div', 'detail-player-actions');
      const viewGroup = node('button', 'button button-secondary', 'Ver recomendaciones de este jugador'); viewGroup.type = 'button';
      viewGroup.addEventListener('click', () => showPlayerRecommendations(recommendation.id, null, playerName(recommendation)));
      if (canRecommend()) {
        const also = node('button', 'button button-primary', 'Recomendar también'); also.type = 'button';
        also.addEventListener('click', () => recommendAlso(recommendation)); playerActions.append(also);
      }
      playerActions.append(viewGroup); body.append(playerActions);
      body.append(renderProof(data.proof), renderEvents(data.events));
      if (canManage(recommendation)) {
        body.append(renderActionForm(recommendation, true));
        if (recommendation.club?.source === 'manual' && recommendation.club_validated !== true) {
          const validation = node('details', 'club-validation');
          validation.append(node('summary', '', 'Revisar y validar este club para el catálogo'), renderActionForm(recommendation, true, true));
          body.append(validation);
        }
      } else if (recommendation.can_add_info === true) body.append(renderActionForm(recommendation, false));
    } catch (error) {
      if (!request.current() || cancelled(error) || !dialog.open) return;
      $('detail-title').textContent = 'No pudimos cargar el detalle';
      const notice = node('div', 'feedback', message(error)); notice.setAttribute('role', 'alert');
      const retry = node('button', 'button button-secondary', 'Reintentar'); retry.type = 'button'; retry.addEventListener('click', () => openDetail(id));
      $('detail-body').replaceChildren(notice, retry);
    }
  }

  function invalidateClubSearch() {
    clearClub(); cancelChannel('clubs');
    $('clubs-more').textContent = 'Cargar más clubes'; delete $('clubs-more').dataset.retry;
    loadClubs();
  }

  $('back-button').addEventListener('click', goBack);
  $('boot-retry').addEventListener('click', boot);
  $('recommend-form').addEventListener('submit', createRecommendation);
  $('new-recommendation').addEventListener('click', newRecommendation);
  $('dashboard-recommend').addEventListener('click', () => activateTab('recommend', true));
  $('reference-clear').addEventListener('click', () => { clearRecommendationReference(); $('player-first-name').focus(); });
  $('success-detail').addEventListener('click', () => openDetail(state.successId));
  $('manual-club-toggle').addEventListener('change', () => setManualClub());
  for (const radio of document.querySelectorAll('[name="search-route"]')) radio.addEventListener('change', () => updateRoute());
  $('club-province').addEventListener('change', () => {
    if (route() === 'province') $('club-competition').value = '';
    $('club-query').value = ''; invalidateClubSearch();
  });
  $('club-competition').addEventListener('change', () => {
    const membership = route() === 'province' && state.selectedClub?.competitions?.find((entry) => String(entry.id) === $('club-competition').value);
    if (membership) {
      applyClubCompetition(membership); state.clubAutoCompetition = true;
      clearPlayer(true); showClubSummary(); return;
    }
    state.clubAutoCompetition = false;
    if (route() === 'competition') $('club-province').value = '';
    $('club-query').value = ''; invalidateClubSearch();
  });
  $('club-query').addEventListener('input', () => {
    clearClub(); cancelChannel('clubs');
    $('club-choice').replaceChildren(option('', 'Buscando clubes…', true));
    debounce('clubs', () => loadClubs());
  });
  $('club-choice').addEventListener('change', selectClub);
  $('clubs-more').addEventListener('click', () => {
    const retry = $('clubs-more').dataset.retry === 'true';
    $('clubs-more').textContent = 'Cargar más clubes'; delete $('clubs-more').dataset.retry;
    loadClubs(!retry);
  });
  $('player-category').addEventListener('change', () => {
    updateCustomCategory(); clearPlayer(false); if ($('player-lookup').open) loadPlayers();
  });
  $('custom-category').addEventListener('input', () => {
    clearPlayer(false); if ($('player-lookup').open) debounce('players', () => loadPlayers());
  });
  $('player-lookup').addEventListener('toggle', () => { if ($('player-lookup').open) loadPlayers(); });
  $('player-query').addEventListener('input', () => { cancelChannel('players'); debounce('players', () => loadPlayers()); });
  $('player-choice').addEventListener('change', selectPlayer);
  $('players-more').addEventListener('click', () => loadPlayers($('players-more').dataset.retry !== 'true'));
  for (const id of ['player-first-name', 'player-last-name']) $(id).addEventListener('input', () => {
    if (state.referenceRecommendation) clearRecommendationReference(false);
    state.selectedPlayer = null; clearAutoPlayerProfile(); clearAutoPlayerAge(); $('player-choice').value = ''; updatePlayerLookup();
  });
  $('transfermarkt-url').addEventListener('input', () => { state.playerAutoTransfermarktUrl = null; });
  $('player-age').addEventListener('input', () => { state.playerAutoAge = null; });
  $('player-position').addEventListener('change', updateSector);
  $('recommend-reason').addEventListener('input', () => { $('reason-count').textContent = `${$('recommend-reason').value.length} / 4000`; });
  for (const input of $('recommend-form').querySelectorAll('input,select,textarea')) {
    input.addEventListener('input', () => { input.setCustomValidity(''); input.removeAttribute('aria-invalid'); });
    input.addEventListener('invalid', () => input.setAttribute('aria-invalid', 'true'));
  }
  $('mine-status').addEventListener('change', () => loadList());
  $('mine-refresh').addEventListener('click', refreshOverview);
  $('mine-more').addEventListener('click', () => loadList(true));
  $('mine-only').addEventListener('change', () => loadList());
  $('player-filter-clear').addEventListener('click', () => {
    state.rankedPlayerFilter = null; $('player-filter').hidden = true; $('player-filter-name').textContent = ''; loadList();
  });
  $('mine-query').addEventListener('input', () => {
    cancelChannel('list'); state.list.loaded = false; $('mine-more').disabled = true;
    debounce('list-query', () => loadList());
  });
  for (const tab of document.querySelectorAll('[data-tab]')) {
    tab.addEventListener('click', () => activateTab(tab.dataset.tab));
    tab.addEventListener('keydown', (event) => {
      if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
      event.preventDefault();
      const tabs = [...document.querySelectorAll('[data-tab]')].filter((entry) => !entry.hidden);
      const current = tabs.indexOf(tab);
      const index = event.key === 'Home' ? 0 : event.key === 'End' ? tabs.length - 1 : (current + (event.key === 'ArrowRight' ? 1 : -1) + tabs.length) % tabs.length;
      activateTab(tabs[index].dataset.tab, true);
    });
  }
  $('detail-close').addEventListener('click', () => $('detail-dialog').close());
  $('detail-dialog').addEventListener('close', () => {
    for (const [key] of channels) if (key === 'detail' || key.startsWith('event-proof:')) cancelChannel(key);
    state.currentDetailId = null;
  });
  window.addEventListener('pagehide', () => {
    for (const [key] of channels) cancelChannel(key);
    for (const timer of timers.values()) clearTimeout(timer);
    timers.clear();
  });
  window.addEventListener('pageshow', (event) => {
    if (event.persisted) { clearSessionState(); state.expired = false; boot(); }
    else checkSessionIdentity();
  });
  window.addEventListener('storage', (event) => { if (event.key === SESSION_KEY || event.key === null) checkSessionIdentity(); });
  window.addEventListener('message', (event) => {
    if (event.origin !== window.location.origin || event.source !== window.parent || event.data?.type !== 'club-abierto:scouting-context') return;
    applyPanelContext(event.data.panel_context);
  });
  document.addEventListener('visibilitychange', () => { if (!document.hidden) checkSessionIdentity(); });
  window.addEventListener('hashchange', () => {
    if (state.actor && ['#gestion', '#tablero'].includes(location.hash)) activateTab('mine');
    else if (state.actor && location.hash === '#mis-recomendaciones') { $('mine-only').checked = true; state.list.loaded = false; activateTab('mine'); }
    else if (state.actor && location.hash === '#recomendar') activateTab('recommend');
  });
  boot();
})();
