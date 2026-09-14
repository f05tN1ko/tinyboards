-- Remove the interface_language column; language preference is now handled
-- client-side by the frontend i18n module (tinyboards_locale cookie).
ALTER TABLE users DROP COLUMN IF EXISTS interface_language;
