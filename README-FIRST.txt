KG BY DESIGN — MEDIA MIGRATION

1. Put these two files in the same kgbydesign-site folder as index.html:
   - migrate-assets.ps1
   - run-migration.bat

2. Double-click run-migration.bat.

The script will:
- Find every image/video still hosted in WordPress
- Download it into an assets folder
- Update index.html to use those local files
- Preserve a backup named index-before-asset-migration.html

Do not change Cloudflare DNS until the updated index.html and assets folder have been uploaded to GitHub.
