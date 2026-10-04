# Sarman - External & Mirror Forges Harvester Worker

Bu depo, Orange..Cat ekosisteminin **SourceHut, bağımsız Git platformları ve yansılar için harici tarayıcı uydu işçisidir** (External Worker Shard Producer).

## Lisans
Bu depo **GNU Affero General Public License v3.0 (AGPLv3)** ile lisanslanmıştır.

## İş Akışı ve Görevler
- **Zamanlanmış Tarama:** GitHub Actions üzerinden her 3 saatte bir (`30 */3 * * *`) çalışır.
- **Harici Platform Taraması:** SourceHut ve bağımsız Git platformlarındaki açık kaynaklı projelerin sürümlerini tarar.
- **Shard Çıktısı:** `external_shard.db` SQLite dosyasını `latest` release etiketi altında yayınlar ve `sarman..kedi` ana veritabanı deposuna girdi sağlar.
