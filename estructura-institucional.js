(function(){
'use strict';
const API='https://sziuyjicqyxnmbgtbopg.supabase.co/functions/v1/estructura-institucional-api';
const normalize=s=>String(s||'').normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/\s+/g,' ').trim();
const safe=s=>String(s==null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;':'&quot;',"'":'&#39;'}[c]));
const link=(url,validated)=>{if(!validated||!url)return '';try{const u=new URL(url);if(u.protocol!=='https:'||!/(^|\.)linkedin\.com$/i.test(u.hostname)||!/^\/in\//.test(u.pathname))return '';}catch(e){return '';}return ' <a class="ei-linkedin" href="'+safe(url)+'" target="_blank" rel="noopener noreferrer" aria-label="Perfil de LinkedIn validado">in</a>'};
let data=null;
function render(){
 const root=document.getElementById('ei-root');if(!root||!data)return;
 const term=normalize(root.querySelector('#ei-search').value),type=root.querySelector('#ei-type').value,group=root.querySelector('#ei-group').value;
 const people=new Map((data.personas||[]).map(p=>[normalize(p.nombre_completo),p]));
 const rows=(data.asambleistas||[]).filter(a=>(type==='todos'||normalize(a.condicion)===type)&&(group==='todos'||String(a.agrupacion_origen||'Pendiente de verificar')===group)&&(!term||normalize(a.nombre_completo).includes(term)));
 root.querySelector('#ei-count').textContent=rows.length+' resultados';
 root.querySelector('#ei-results').innerHTML=rows.map(a=>{const p=people.get(normalize(a.nombre_completo));return '<tr><td>'+safe(a.nombre_completo)+link(a.linkedin_validado?a.linkedin_url:(p?.linkedin_validado?p?.linkedin_url:null),a.linkedin_validado||p?.linkedin_validado)+'</td><td>'+safe(a.condicion)+'</td><td>'+safe(a.agrupacion_origen||'Pendiente de verificar')+'</td></tr>'}).join('')||'<tr><td colspan="3">No se encontraron asambleístas.</td></tr>';
}
async function open(){
 let root=document.getElementById('ei-root');
 if(!root){root=document.createElement('section');root.id='ei-root';root.className='ei-overlay';root.innerHTML='<div class="ei-panel"><button id="ei-close" type="button">Cerrar ×</button><h2>Estructura institucional</h2><p>Asambleístas titulares y suplentes</p><div class="ei-filters"><input id="ei-search" placeholder="Buscar por nombre o apellido" aria-label="Buscar asambleísta"><select id="ei-type" aria-label="Condición"><option value="todos">Titulares y suplentes</option><option value="titular">Titulares</option><option value="suplente">Suplentes</option></select><select id="ei-group" aria-label="Agrupación"><option value="todos">Todas las agrupaciones</option></select></div><p id="ei-count"></p><div class="ei-tablewrap"><table><thead><tr><th>Nombre</th><th>Condición</th><th>Agrupación o partido de origen</th></tr></thead><tbody id="ei-results"></tbody></table></div><p id="ei-message" role="status"></p></div>';document.body.appendChild(root);root.querySelector('#ei-close').onclick=()=>root.remove();['ei-search','ei-type','ei-group'].forEach(id=>root.querySelector('#'+id).addEventListener(id==='ei-search'?'input':'change',render));}
 root.querySelector('#ei-message').textContent='Cargando datos institucionales…';
 try{
  const token=typeof obtenerTokenSesionClub==='function'?obtenerTokenSesionClub():'';
  if(!token)throw Error('Iniciá sesión para consultar la estructura.');
  const res=await fetch(API,{method:'POST',headers:{'Content-Type':'application/json','x-club-session':token},body:JSON.stringify({accion:'estructura_institucional'})});
  const obj=await res.json();if(!res.ok||!obj.ok)throw Error(obj.mensaje||'Error al consultar la estructura.');
  data=obj;
  const groups=[...new Set((data.asambleistas||[]).map(x=>x.agrupacion_origen||'Pendiente de verificar'))].sort((a,b)=>a.localeCompare(b,'es'));
  root.querySelector('#ei-group').innerHTML='<option value="todos">Todas las agrupaciones</option>'+groups.map(g=>'<option value="'+safe(g)+'">'+safe(g)+'</option>').join('');
  root.querySelector('#ei-message').textContent='';render();
 }catch(e){root.querySelector('#ei-message').textContent=e.message||'No se pudo cargar la información';}
}
document.addEventListener('click',e=>{const button=e.target.closest('button');if(!button)return;const label=normalize(button.textContent);if(label==='estructura institucional' || label.startsWith('estructura institucional ')){e.preventDefault();e.stopImmediatePropagation();open();}},true);
})();
