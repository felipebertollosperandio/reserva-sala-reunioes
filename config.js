// Backend proprio (PostgREST + PostgreSQL no VPS), servido em /rest/v1 do mesmo dominio.
// Os nomes "supabase*" sao mantidos porque o app.js os usa internamente; nao e mais o Supabase.
// supabaseUrl = a origem que serviu esta pagina. Como a API vive em /rest/v1 do mesmo host,
// usar window.location.origin evita ter que editar aqui ao trocar de dominio.
window.RESERVA_DB = {
  supabaseUrl: window.location.origin,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiJ9.d5I-kYywGfkbjVUuT-NdVB3FdVR-a5vJCu-3CWVPsng",
};
