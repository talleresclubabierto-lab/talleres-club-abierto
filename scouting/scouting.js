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
    cerrada: 'Cerrada'
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
    actor: null, bootstrap: null, expired: false, activeToken: '', sessionGeneration: 0, activeTab: 'mine',
    clubs: new Map(), players: new Map(), clubsCursor: null, playersCursor: null, clubsQuery: null, playersQuery: null,
    selectedClub: null, selectedPlayer: null, clubAutoCompetition: false, playerAutoTransfermarktUrl: null, createRequestId: null, createPending: null,
    createBusy: false, successId: null, currentDetailId: null,
    lists: { mine: { items: [], cursor: null, loaded: false }, admin: { items: [], cursor: null, loaded: false } },
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

  function date(value) {
    const parsed = new Date(value);
    if (!value || Number.isNaN(parsed.getTime())) return 'Fecha no disponible';
    return new Intl.DateTimeFormat('es-AR', {
      dateStyle: 'medium', timeStyle: 'short', hour12: false, timeZone: 'America/Argentina/Buenos_Aires'
    }).format(parsed);
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
    state.actor = null; state.bootstrap = null; state.activeToken = '';
    state.clubs.clear(); state.players.clear(); state.mutations.clear();
    state.selectedClub = null; state.selectedPlayer = null; state.playerAutoTransfermarktUrl = null; state.createPending = null;
    state.createRequestId = null; state.successId = null; state.currentDetailId = null; state.createBusy = false;
    state.clubAutoCompetition = false; state.clubsQuery = null; state.playersQuery = null;
    state.lists.mine = { items: [], cursor: null, loaded: false };
    state.lists.admin = { items: [], cursor: null, loaded: false };
    $('recommend-form').reset();
    updateClubReference(); updatePlayerReview();
    for (const id of ['mine-list', 'admin-list', 'detail-body']) $(id).replaceChildren();
    for (const id of ['success-description', 'selected-club-name', 'selected-club-description', 'actor-label', 'mine-count', 'admin-count']) $(id).textContent = '';
    $('admin-query').value = '';
    $('club-choice').replaceChildren(option('', 'Elegí una provincia para buscar', true));
    $('player-choice').replaceChildren(option('', 'Seleccioná una categoría', true));
    setFeedback('create-feedback', '');
    $('create-success').hidden = true; $('recommend-layout').hidden = false;
    $('create-fields').disabled = false;
    $('create-submit').disabled = false; $('create-submit').textContent = 'Enviar recomendación ↗';
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
      $('tab-admin').hidden = data.actor.role !== 'admin';
      $('boot-panel').hidden = true;
      $('application').hidden = false;
      $('mine-only').checked = location.hash === '#mis-recomendaciones';
      activateTab(location.hash === '#gestion' && data.actor.role === 'admin' ? 'admin' : location.hash === '#recomendar' ? 'recommend' : 'mine');
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
    for (const id of ['mine-status', 'admin-status']) replaceOptions($(id), Object.entries(STATUS).map(([value, label]) => ({ value, label })), 'Todos los estados');
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
    if (name === 'admin' && state.actor?.role !== 'admin') return;
    if (!['recommend', 'mine', 'admin'].includes(name)) return;
    state.activeTab = name;
    for (const tab of document.querySelectorAll('[data-tab]')) {
      const active = tab.dataset.tab === name;
      tab.setAttribute('aria-selected', String(active)); tab.tabIndex = active ? 0 : -1;
      $(`panel-${tab.dataset.tab}`).hidden = !active;
      if (active && focus) tab.focus();
    }
    if (name !== 'recommend' && !state.lists[name].loaded) loadList(name);
  }

  function clearPlayer(clearCategory = false) {
    cancelChannel('players'); clearDebounce('players');
    clearAutoPlayerProfile();
    state.selectedPlayer = null; state.players.clear(); state.playersCursor = null;
    $('player-choice').replaceChildren(option('', 'Seleccioná una categoría', true));
    $('players-more').hidden = true;
    $('player-query').value = '';
    $('player-first-name').value = ''; $('player-last-name').value = '';
    $('player-position').value = ''; $('player-sector').value = 'no_especificado';
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
    const available = !manualClub() && Boolean(state.selectedClub) && Number(state.bootstrap?.catalogue?.player_count || 0) > 0;
    $('player-lookup').hidden = !available;
    if (!available) $('player-lookup').open = false;
    $('player-manual-help').textContent = state.selectedPlayer ? 'Datos del jugador seleccionado. Podés completar la posición que observaste.' : 'Completá los datos del jugador. No necesita figurar en el catálogo.';
    updatePlayerReview();
  }

  function updateSector() {
    const relevant = ['Lateral', 'Delantero Extremo'].includes($('player-position').value);
    $('sector-field').hidden = !relevant; $('player-sector').disabled = !relevant;
    if (!relevant) $('player-sector').value = 'no_especificado';
  }

  async function loadPlayers(more = false) {
    if (!state.selectedClub || manualClub() || $('player-lookup').hidden) return;
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
    const player = state.players.get($('player-choice').value);
    if (!player) return;
    state.selectedPlayer = player;
    $('player-first-name').value = player.first_name || '';
    $('player-last-name').value = player.last_name || '';
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
    if (!$('recommend-form').reportValidity()) return null;
    if (!manualClub() && !state.selectedClub) {
      setFeedback('create-feedback', 'Seleccioná un equipo del listado o activá Otro club para ingresarlo manualmente.', 'error', true);
      return null;
    }
    const required = [['player-first-name', 2, 'El nombre'], ['player-last-name', 2, 'El apellido'], ['recommend-reason', 20, 'El motivo']];
    if (manualClub()) required.unshift(['manual-city', 2, 'La ciudad'], ['manual-club-name', 2, 'El nombre del club'], ['manual-league', 2, 'La liga']);
    if ($('player-category').value === OTHER_CATEGORY) required.push(['custom-category', 2, 'La categoría']);
    for (const [id, minimum, label] of required) if (!validateField(id, minimum, label)) return null;
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
      club_id: manualClub() ? null : state.selectedClub.id,
      club_manual: manualClub() ? { province: $('manual-province').value, city: $('manual-city').value.trim(), name: $('manual-club-name').value.trim(), league: $('manual-league').value.trim() } : null,
      competition_id: manualClub() ? null : state.selectedClub.competition_id || $('club-competition').value || null,
      category: category(), player_id: state.selectedPlayer?.id || null,
      player: { first_name: $('player-first-name').value.trim(), last_name: $('player-last-name').value.trim(), position: $('player-position').value, sector: $('player-sector').disabled ? 'no_especificado' : $('player-sector').value },
      reason: $('recommend-reason').value.trim(), observation: $('recommend-observation').value.trim(),
      video_url: safeUrl($('video-url').value.trim(), 'video'), transfermarkt_url: safeUrl($('transfermarkt-url').value.trim(), 'transfermarkt')
    };
  }

  async function createRecommendation(event) {
    event.preventDefault();
    if (state.createBusy || state.expired) return;
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
      state.lists.mine.loaded = false; state.lists.admin.loaded = false;
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
        $('create-submit').disabled = false;
        $('create-submit').textContent = state.createPending ? 'Reintentar envío' : 'Enviar recomendación ↗';
      }
    }
  }

  function newRecommendation() {
    $('recommend-form').reset();
    for (const input of $('recommend-form').querySelectorAll('input,select,textarea')) input.setCustomValidity('');
    state.createRequestId = null; state.createPending = null; state.successId = null;
    $('manual-club-toggle').checked = Number(state.bootstrap?.catalogue?.club_count || 0) === 0;
    $('create-success').hidden = true; $('recommend-layout').hidden = false;
    $('create-fields').disabled = false; $('reason-count').textContent = '0 / 4000';
    clearClub(); updateRoute(); setManualClub(false); updateCustomCategory();
    setFeedback('create-feedback', '');
    $('club-section-title').scrollIntoView({ block: 'start' });
    const target = manualClub() ? $('manual-province') : $('club-province'); target.focus();
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
    const content = node('div');
    content.append(node('h3', '', playerName(recommendation)));
    content.append(node('p', 'club-line', [recommendation.club?.name, recommendation.club?.city, recommendation.club?.province].filter(Boolean).join(' · ') || 'Club sin información'));
    content.append(node('p', 'author-line', `Recomienda: ${recommendation.author?.name || 'Socio de Club Abierto'}`));
    const meta = node('div', 'card-meta');
    for (const text of [recommendation.category, recommendation.player?.position, date(recommendation.created_at), recommendation.code]) if (text) meta.append(node('span', '', text));
    content.append(meta);
    const actions = node('div', 'card-actions');
    actions.append(statusBadge(recommendation.status));
    const button = node('button', 'button button-secondary', 'Ver detalle'); button.type = 'button';
    button.setAttribute('aria-label', `Ver recomendación de ${playerName(recommendation)}`);
    button.addEventListener('click', () => openDetail(recommendation.id));
    actions.append(button); article.append(content, actions); return article;
  }

  function renderList(kind) {
    const list = $(`${kind}-list`); list.replaceChildren();
    const items = state.lists[kind].items;
    if (!items.length) {
      const empty = node('div', 'empty-state');
      const filtered = Boolean($(`${kind}-status`).value || kind === 'admin' && $('admin-query').value.trim());
      empty.append(node('h3', '', filtered ? 'No hay recomendaciones con estos filtros' : kind === 'mine' ? $('mine-only').checked ? 'Todavía no enviaste recomendaciones' : 'Todavía no hay recomendaciones del club' : 'Todavía no hay recomendaciones para revisar'));
      empty.append(node('p', '', filtered ? 'Probá con otro estado o modificá la búsqueda.' : kind === 'mine' ? 'Compartí un aporte deportivo. Su autor, estado y devoluciones quedarán visibles para todos los socios.' : 'Los aportes de los socios aparecerán en esta bandeja.'));
      if (kind === 'mine' && !filtered) {
        const button = node('button', 'button button-primary', 'Recomendar jugador'); button.type = 'button';
        button.addEventListener('click', () => activateTab('recommend', true)); empty.append(button);
      }
      list.append(empty);
    } else for (const item of items) list.append(card(item));
    $(`${kind}-count`).textContent = items.length ? `${items.length} ${items.length === 1 ? 'recomendación cargada' : 'recomendaciones cargadas'}` : '';
  }

  async function loadList(kind, more = false) {
    if (!state.actor || state.expired || kind === 'admin' && state.actor.role !== 'admin') return;
    const request = requestChannel(`list-${kind}`);
    const listState = state.lists[kind];
    const list = $(`${kind}-list`);
    const moreButton = $(`${kind}-more`);
    if (!more) {
      listState.items = []; listState.cursor = null; listState.loaded = false;
      const loading = node('div', 'list-loading');
      const ring = node('span', 'loading-ring'); ring.setAttribute('aria-hidden', 'true');
      loading.append(ring, node('span', '', 'Cargando recomendaciones…')); list.replaceChildren(loading);
      $(`${kind}-count`).textContent = ''; moreButton.hidden = true;
    }
    list.setAttribute('aria-busy', 'true'); moreButton.disabled = true;
    $(`${kind}-refresh`).disabled = true;
    setFeedback(`${kind}-feedback`, '');
    try {
      const payload = { status: $(`${kind}-status`).value || null, cursor: more ? listState.cursor : null };
      if (kind === 'admin') payload.query = $('admin-query').value.trim();
      else payload.mine_only = $('mine-only').checked;
      const data = await api(kind === 'admin' ? 'admin_list' : 'feed', payload, request.signal);
      if (!request.current()) return;
      const existing = new Map(listState.items.map((item) => [String(item.id), item]));
      for (const item of Array.isArray(data.items) ? data.items : []) existing.set(String(item.id), item);
      listState.items = [...existing.values()]; listState.cursor = data.next_cursor || null; listState.loaded = true;
      renderList(kind); moreButton.hidden = !listState.cursor;
    } catch (error) {
      if (!request.current() || cancelled(error)) return;
      if (!more) list.replaceChildren();
      setFeedback(`${kind}-feedback`, `${message(error)} Usá Actualizar para volver a intentar.`);
    } finally {
      if (request.current()) { list.setAttribute('aria-busy', 'false'); moreButton.disabled = false; $(`${kind}-refresh`).disabled = false; }
    }
  }

  function detailPair(label, value) {
    const group = node('div'); group.append(node('dt', '', label), node('dd', '', value || 'No informado')); return group;
  }

  function textSection(title, text) {
    const section = node('section', 'detail-section'); section.append(node('h3', '', title), node('p', '', text || 'Sin información adicional.')); return section;
  }

  function renderProof(proof) {
    const details = node('details', 'proof-panel'); details.append(node('summary', '', 'Constancia de registro y auditoría'));
    const content = node('div', 'proof-content');
    const recognised = proof && Object.hasOwn(PROOF_STATUS, proof.status);
    content.append(node('p', '', recognised ? PROOF_STATUS[proof.status] : 'No hay una constancia de anclaje disponible para mostrar.'));
    if (proof?.status === 'registrada') content.append(node('p', '', 'El aporte tiene un registro de auditoría. Su anclaje en blockchain todavía no está confirmado.'));
    else if (proof?.status === 'preparada') content.append(node('p', '', 'El registro está preparado para su anclaje. Todavía no hay confirmación en blockchain.'));
    else if (proof?.status === 'enviada') content.append(node('p', '', 'El anclaje fue enviado y está pendiente de confirmación.'));
    const metadata = node('dl');
    for (const [label, value] of [['Huella del registro inicial', proof?.commitment_hash], ['Registro de auditoría', proof?.audit_event_id], ['Huella en auditoría general', proof?.audit_event_hash], ['Lote', proof?.lot_id], ['Raíz Merkle', proof?.merkle_root], ['Transacción', proof?.transaction_hash], ['Bloque confirmado', proof?.status === 'anclada' ? proof?.block_number : null]]) {
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
    if (/club_validated|club_validado/.test(event.type || '')) return 'Club validado para el catálogo';
    if (/created|cread|recibida/.test(event.type || '')) return 'Recomendación recibida';
    if (/info|aporte/.test(event.type || '') && !/solicit/.test(event.type || '')) return 'Información agregada';
    return STATUS[event.status] || 'Actualización de la recomendación';
  }

  function renderEvents(events) {
    const section = node('section', 'detail-section'); section.append(node('h3', '', 'Historial de seguimiento'));
    const rows = (Array.isArray(events) ? [...events] : []).sort((a, b) => new Date(a.created_at).getTime() - new Date(b.created_at).getTime());
    if (!rows.length) { section.append(node('p', '', 'Todavía no hay novedades de seguimiento.')); return section; }
    const timeline = node('ol', 'timeline');
    for (const event of rows) {
      const item = node('li');
      item.append(node('div', 'timeline-heading', eventTitle(event)));
      item.append(node('div', 'timeline-meta', `${date(event.created_at)} · ${event.actor_name || (event.actor_role === 'admin' ? 'Equipo evaluador' : 'Socio')}${event.actor_role === 'admin' && event.actor_name ? ' · Equipo evaluador' : ''}`));
      if (event.message) item.append(node('p', 'timeline-message', event.message));
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
      if (previous?.busy || state.expired) return;
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
        state.lists.mine.loaded = false; state.lists.admin.loaded = false;
        if (state.activeTab === 'mine' || state.activeTab === 'admin') loadList(state.activeTab);
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
        ['Posición', recommendation.player?.position], ['Sector', { derecha: 'Derecha', izquierda: 'Izquierda', ambos: 'Ambos', no_especificado: 'Sin especificar' }[recommendation.player?.sector] || 'Sin especificar']
      ]) grid.append(detailPair(label, value));
      grid.prepend(detailPair('Socio que recomienda', recommendation.author?.name || 'Socio de Club Abierto'));
      body.append(grid, textSection('Motivo de la recomendación', recommendation.reason));
      if (recommendation.observation) body.append(textSection('Contexto de la observación', recommendation.observation));
      if (recommendation.video_url || recommendation.transfermarkt_url) {
        const links = node('div', 'detail-links'); appendLink(links, recommendation.video_url, 'Ver video', 'video'); appendLink(links, recommendation.transfermarkt_url, 'Consultar Transfermarkt', 'transfermarkt');
        if (links.childElementCount) body.append(links);
      }
      body.append(renderProof(data.proof), renderEvents(data.events));
      if (recommendation.can_manage === true) {
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
    state.selectedPlayer = null; clearAutoPlayerProfile(); $('player-choice').value = ''; updatePlayerLookup();
  });
  $('transfermarkt-url').addEventListener('input', () => { state.playerAutoTransfermarktUrl = null; });
  $('player-position').addEventListener('change', updateSector);
  $('recommend-reason').addEventListener('input', () => { $('reason-count').textContent = `${$('recommend-reason').value.length} / 4000`; });
  for (const input of $('recommend-form').querySelectorAll('input,select,textarea')) {
    input.addEventListener('input', () => { input.setCustomValidity(''); input.removeAttribute('aria-invalid'); });
    input.addEventListener('invalid', () => input.setAttribute('aria-invalid', 'true'));
  }
  for (const kind of ['mine', 'admin']) {
    $(`${kind}-status`).addEventListener('change', () => loadList(kind));
    $(`${kind}-refresh`).addEventListener('click', () => loadList(kind));
    $(`${kind}-more`).addEventListener('click', () => loadList(kind, true));
  }
  $('mine-only').addEventListener('change', () => loadList('mine'));
  $('admin-query').addEventListener('input', () => { cancelChannel('list-admin'); debounce('admin-query', () => loadList('admin')); });
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
  $('detail-dialog').addEventListener('close', () => { cancelChannel('detail'); state.currentDetailId = null; });
  window.addEventListener('pagehide', () => { for (const [key] of channels) cancelChannel(key); });
  window.addEventListener('pageshow', (event) => {
    if (event.persisted) { clearSessionState(); state.expired = false; boot(); }
    else checkSessionIdentity();
  });
  window.addEventListener('storage', (event) => { if (event.key === SESSION_KEY || event.key === null) checkSessionIdentity(); });
  document.addEventListener('visibilitychange', () => { if (!document.hidden) checkSessionIdentity(); });
  window.addEventListener('hashchange', () => {
    if (state.actor && location.hash === '#gestion') activateTab('admin');
    else if (state.actor && location.hash === '#mis-recomendaciones') { $('mine-only').checked = true; state.lists.mine.loaded = false; activateTab('mine'); }
    else if (state.actor && location.hash === '#recomendar') activateTab('recommend');
  });
  boot();
})();
