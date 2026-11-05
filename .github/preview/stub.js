(function(){
  const q = () => { const r = new Proxy(function(){}, { get:(t,k)=> k==='then' ? (res=>res({data:[],error:null})) : r, apply:()=>r }); return r; };
  const auth = { getSession: async()=>({data:{session:null}}), onAuthStateChange: ()=>({data:{subscription:{unsubscribe(){}}}}), getUser: async()=>({data:{user:null}}) };
  window.supabase = { createClient: () => ({ auth, from: q, rpc: q, storage: { from: q }, channel: q, removeChannel(){} }) };
})();
