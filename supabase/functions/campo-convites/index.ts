import {criarHandler} from './handler.ts';
Deno.serve(criarHandler({SUPABASE_URL:Deno.env.get('SUPABASE_URL')!,SUPABASE_ANON_KEY:Deno.env.get('SUPABASE_ANON_KEY')!,SUPABASE_SERVICE_ROLE_KEY:Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!}));
