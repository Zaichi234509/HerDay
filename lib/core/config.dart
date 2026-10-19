/// HerDay — Supabase connection.
///
/// These defaults point at the live "herday" Supabase project so the app
/// works out of the box. The anon key is safe to ship in the client:
/// every table is protected by Row Level Security (auth.uid() = user_id).
///
/// Override at run/build time if you ever move to another project:
///   flutter run --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
///               --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://qewzyquyeqgpixliqfyz.supabase.co',
);

/// Timezone used for daily reminder scheduling. HerDay is made for the
/// Philippines — change this if she ever lives in another timezone.
const String herDayTimezone = 'Asia/Manila';

/// Public Supabase Storage bucket for memory / journal photos.
const String photosBucket = 'memories';

const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFld3p5cXV5ZXFncGl4bGlxZnl6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTIzODE4NDEsImV4cCI6MjEwNzk1Nzg0MX0.YQTNuf5-bWNrZjBUJ9UbyxoAjDTSGggh9dSlxZkVKak',
);
