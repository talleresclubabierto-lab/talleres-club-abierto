(function(){
'use strict';
const endpoint='https://sziuyjicqyxnmbgtbopg.supabase.co/functions/v1/comunidad-formativa-api';
const token=sessionStorage.getItem('TD_cf_family_session_v1')||'';
const section=document.body.dataset.section||'';
const status=document.getElementById('panel-status');
const profileUrl='/comunidad-formativa/vinculo/';
async function call(action,data){
 const response=await fetch(endpoint,{method:'POST',mode:'cors',cache:'no-store',credentials:'omit',headers:{'Content-Type':'application/json','X-Club-Session':token},body:JSON.stringify(Object.assign({action},data||{}))});
 const result=await response.json().catch(()=>({}));
 if(!response.ok)throw new Error(result.error||'No se pudo completar la operación.');
 return result;
}
function text(id,value){const el=document.getElementById(id);if(el)el.textContent=value||'—';}
function logout(){sessionStorage.removeItem('TD_cf_family_session_v1');location.replace('/comunidad-formativa.html');}
const logoutButton=document.getElementById('logout-button');if(logoutButton)logoutButton.addEventListener('click',logout);
function displayCase(c){
 const categories={consulta:'Consulta',sugerencia:'Sugerencia',posible_ventaja_indebida:'Presunta solicitud de dinero o ventaja indebida',posible_intervencion_irregular:'Presunta intervención irregular de representantes',posible_conflicto_intereses:'Posible conflicto de intereses',criterio_deportivo:'Criterios deportivos presuntamente irregulares',maltrato_discriminacion:'Maltrato o discriminación',posible_represalia:'Posibles represalias',salud_proteccion:'Salud o protección',educacion_acompanamiento:'Educación o acompañamiento',entrenamiento:'Entrenamiento',alimentacion:'Alimentación',transporte:'Transporte',infraestructura:'Infraestructura',otra_situacion:'Otra incidencia'};
 const states={recibida:'Recibida',en_evaluacion:'En evaluación',informacion_solicitada:'Información solicitada',en_investigacion:'En investigación',resuelta:'Resuelta',archivada:'Archivada',reabierta:'Reabierta'};
 const row=document.createElement('article');row.className='case-row';
 const title=document.createElement('strong');title.textContent=c.codigo+' · '+(categories[c.categoria]||'Presentación');
 const created=new Date(c.creada_en);
 const meta=document.createElement('small');meta.textContent='Estado: '+(states[c.estado]||'Recibida')+' · '+(Number.isNaN(created.getTime())?'':new Intl.DateTimeFormat('es-AR',{dateStyle:'short'}).format(created));
 row.append(title,meta);return row;
}
async function boot(){
 if(!token){location.replace('/comunidad-formativa.html#otp-panel');return;}
 try{
   const result=await call('family_profile');
   const profile=result.profile;
   if(!profile)throw new Error('family_session_expired');
   document.body.classList.add('family-ready');
   const badge=document.getElementById('access-badge');if(badge)badge.textContent='Acceso habilitado';
   text('player-name',profile.player.name);
   text('player-category',profile.player.category||'Categoría no informada');
   text('player-birth',profile.player.birth_date||'No informada');
   text('adult-name',profile.adult.name);
   text('adult-relationship',profile.adult.relationship);
   text('adult-phone',profile.adult.phone);
   text('adult-email',profile.adult.email);
   if(section==='cases'||section==='presentations'||section==='accompaniment')await loadCases();
   if(section==='accompaniment'||section==='integrity')wireCaseForm();
   if(section==='profile')wireUpdateForm();
   if(status)status.textContent='Sesión individual activa. El acceso vence en 8 horas o cuando se cierre la sesión.';
 }catch(error){
   if(String(error).includes('expired')||String(error).includes('required')){
     sessionStorage.removeItem('TD_cf_family_session_v1');
     location.replace('/comunidad-formativa.html#otp-panel');
     return;
   }
   if(status)status.textContent='No se pudo cargar el panel. Volvé a ingresar con un nuevo código.';
 }
}
async function loadCases(){
 const list=document.getElementById('case-list');if(!list)return;
 list.textContent='Cargando presentaciones…';
 try{
   const result=await call('family_cases_list');
   const cases=Array.isArray(result.cases)?result.cases:[];
   list.replaceChildren();
   if(!cases.length){list.textContent='Todavía no hay presentaciones asociadas a este vínculo.';return;}
   for(const item of cases)list.append(displayCase(item));
 }catch(_){list.textContent='No se pudo cargar el seguimiento. Volvé a ingresar con un nuevo código.';}
}
function wireCaseForm(){
 const form=document.getElementById('case-form');if(!form)return;
 form.addEventListener('submit',async function(e){
   e.preventDefault();
   if(!form.reportValidity())return;
   const button=form.querySelector('button[type="submit"]');if(button)button.disabled=true;
   if(status)status.textContent='Enviando de forma cifrada…';
   const data=new FormData(form);
   try{
     const result=await call('family_case_submit',{
       category:data.get('category'),
       reservation:data.get('reservation'),
       narrative:data.get('narrative'),
       mentioned_people:data.get('mentioned_people')||'',
       approx_date:data.get('approx_date')||''
     });
     if(status)status.textContent='Presentación recibida. Código de seguimiento: '+result.code+'. Guardalo para tus consultas.';
     form.reset();
     if(document.getElementById('case-list'))await loadCases();
   }catch(_){
     if(status)status.textContent='No se pudo enviar. Revisá los campos e intentá nuevamente.';
   }finally{if(button)button.disabled=false;}
 });
}
function wireUpdateForm(){
 const form=document.getElementById('update-form');if(!form)return;
 form.addEventListener('submit',async function(e){
   e.preventDefault();if(!form.reportValidity())return;
   const button=form.querySelector('button[type="submit"]');if(button)button.disabled=true;
   const value=new FormData(form).get('requested_change');
   try{
     const result=await call('family_case_submit',{category:'consulta',reservation:'identificada',narrative:'Solicitud de actualización de información: '+value,mentioned_people:'',approx_date:''});
     if(status)status.textContent='Solicitud recibida. Código de seguimiento: '+result.code+'. La información vigente se conserva hasta su revisión.';
     form.reset();
   }catch(_){if(status)status.textContent='No se pudo registrar la solicitud de actualización. Intentá nuevamente.';}
   finally{if(button)button.disabled=false;}
 });
}
boot();
})();