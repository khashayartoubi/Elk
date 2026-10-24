# ELK Docker Logging Stack

یک استک آمادهٔ Docker Compose برای جمع‌آوری، پردازش، جست‌وجو و مشاهدهٔ لاگ کانتینرهای Docker با Elasticsearch، Logstash، Kibana و Filebeat.

فقط کانتینرهایی که صریحاً opt-in شده‌اند جمع‌آوری می‌شوند. لاگ‌ها در Elasticsearch و یک آرشیو NDJSON روزانه روی میزبان نگه‌داری می‌شوند و هر دو با یک سیاست retention قابل تنظیم پاک‌سازی می‌شوند.

## قابلیت‌ها

- کشف خودکار کانتینرهای Docker با Filebeat
- جمع‌آوری فقط از سرویس‌های دارای label `elk_logs: "true"`
- نرمال‌سازی لاگ‌های JSON و نگاشت فیلدهای متداول به ECS
- پشتیبانی از لاگ متن ساده، تشخیص سطح `error`، `warn` و `debug` و حذف رنگ‌های ANSI
- Kibana با احراز هویت فعال
- آرشیو محلی NDJSON روزانه برای هر سرویس
- حذف خودکار ایندکس‌های Elasticsearch و آرشیوهای محلی پس از مدت تعیین‌شده

## معماری

```text
Docker containers ──> Filebeat ──> Logstash ──> Elasticsearch ──> Kibana
                                      └──────> ./logs/*.ndjson
```

| سرویس | مسئولیت |
| --- | --- |
| Elasticsearch | ذخیره‌سازی، جست‌وجو و اجرای ILM retention policy |
| Logstash | نرمال‌سازی و ارسال رخدادها به Elasticsearch و آرشیو محلی |
| Kibana | رابط وب برای جست‌وجو و ساخت dashboard |
| Filebeat | کشف کانتینرهای دارای label و خواندن stdout/stderr آن‌ها |
| setup | ایجاد/به‌روزرسانی حساب‌ها و retention policy هنگام بالا آمدن استک |
| log-cleanup | پاک‌سازی روزانهٔ فایل‌های NDJSON قدیمی |

## پیش‌نیازها

- Docker Engine و Docker Compose v2
- حداقل ۷ گیگابایت RAM آزاد برای سقف حافظهٔ سرویس‌ها
- دسترسی به رجیستری `docker.agahyarai.local`؛ یا جایگزین‌کردن نام imageها در `docker-compose.yml`

## راه‌اندازی

1. از فایل نمونه، فایل تنظیمات محلی بسازید:

   ```bash
   cp .env.example .env
   ```

2. مقادیر `.env`، به‌ویژه رمزها و `LOG_HOST_IP`، را تنظیم کنید. هر سه رمز باید قوی و یکتا باشند.

3. پیکربندی نهایی Compose را پیش از اجرا بررسی کنید:

   ```bash
   docker compose config
   ```

4. سرویس‌ها را build و اجرا کنید:

   ```bash
   docker compose up -d --build
   ```

5. آماده‌شدن اولیه را بررسی کنید:

   ```bash
   docker compose ps
   docker compose logs --tail=100 setup
   ```

پس از پایان موفق `setup`، Kibana در `http://<KIBANA_BIND_IP>:<KIBANA_PORT>` در دسترس است. با `KIBANA_LOGIN_USER` و `KIBANA_LOGIN_PASSWORD` وارد شوید.

> مقدار پیش‌فرض `KIBANA_BIND_IP=127.0.0.1` است؛ بنابراین رابط فقط از همان میزبان قابل دسترسی است. برای دسترسی راه‌دور، آن را فقط همراه با فایروال و reverse proxy دارای TLS تغییر دهید.

## تنظیمات محیطی

تمام تنظیمات در `.env` قرار دارند؛ این فایل نباید commit شود. `.env.example` تنها الگوی قابل‌اشتراک‌گذاری است.

| متغیر | اجباری | مقدار نمونه | توضیح |
| --- | --- | --- | --- |
| `STACK_VERSION` | بله | `9.2.0` | نسخهٔ یکسان Elasticsearch، Logstash، Kibana و Filebeat |
| `KIBANA_BIND_IP` | بله | `127.0.0.1` | IPای که پورت Kibana روی آن bind می‌شود |
| `KIBANA_PORT` | بله | `5601` | پورت رابط Kibana روی میزبان |
| `ES_HEAP` | بله | `1g` | heap اولیه و بیشینهٔ JVM برای Elasticsearch |
| `LOG_HOST_IP` | بله | `192.168.10.154` | نام/IP ثبت‌شده در `host.name` رخدادها؛ IP میزبان Docker را وارد کنید |
| `LOG_SERVICE_TYPE` | بله | `nodejs` | نوع پیش‌فرض سرویس، وقتی label اختصاصی وجود ندارد |
| `LOG_RETENTION_DAYS` | بله | `7` | تعداد روزهای نگه‌داری ایندکس‌ها و فایل‌های آرشیو؛ باید عدد صحیح بزرگ‌تر از صفر باشد |
| `ELASTIC_PASSWORD` | بله | — | رمز حساب مدیریتی داخلی `elastic` |
| `KIBANA_SYSTEM_PASSWORD` | بله | — | رمز حساب داخلی Kibana برای اتصال به Elasticsearch |
| `KIBANA_LOGIN_USER` | بله | — | نام کاربر ورود به Kibana که در setup ایجاد می‌شود |
| `KIBANA_LOGIN_PASSWORD` | بله | — | رمز کاربر ورود به Kibana |

## جمع‌آوری لاگ یک سرویس

در فایل Compose سرویس مقصد، label زیر را اضافه و سرویس را recreate کنید:

```yaml
services:
  api:
    image: example/api:latest
    labels:
      elk_logs: "true"
      # اختیاری؛ در غیر این صورت LOG_SERVICE_TYPE استفاده می‌شود.
      elk_service_type: "nodejs"
```

```bash
docker compose up -d --force-recreate api
```

Filebeat کانتینر را به‌صورت خودکار پیدا می‌کند. سرویس مقصد نیازی به agent، volume یا پورت اضافه ندارد. نام کانتینر پس از نرمال‌سازی در `service.name` ثبت می‌شود.

## قالب پیشنهادی لاگ برنامه

برای بهترین قابلیت جست‌وجو، برنامه لاگ JSON را روی stdout بنویسد:

```json
{
  "timestamp": "2026-10-24T09:30:00.000Z",
  "level": "error",
  "message": "Payment request failed",
  "http": {
    "request": { "method": "POST" },
    "response": { "status_code": 502 }
  },
  "url": { "path": "/payments" }
}
```

| ورودی | فیلد نهایی Elasticsearch |
| --- | --- |
| `timestamp` | `@timestamp` |
| `level` | `log.level` |
| `http` | `http` |
| `url` | `url` |
| نام کانتینر | `service.name` |
| `elk_service_type` | `service.type` |

لاگ متن ساده نیز ذخیره می‌شود و سطح آن از کلمات `error`، `warn` و `debug` تشخیص داده می‌شود.

## Retention policy

`LOG_RETENTION_DAYS` مدت نگه‌داری را هم‌زمان در هر دو محل تعیین می‌کند:

- **Elasticsearch:** سرویس `setup` policy با نام `docker-logs-retention` را ایجاد می‌کند و به همهٔ ایندکس‌های `docker-logs-*`، شامل ایندکس‌های موجود، اعمال می‌کند. Elasticsearch ایندکس‌ها را پس از مدت تعیین‌شده حذف می‌کند.
- **آرشیو محلی:** سرویس `log-cleanup` روزی یک‌بار فایل‌های `./logs/*.ndjson` قدیمی‌تر از این بازه را حذف می‌کند.

برای مثال، جهت نگه‌داری ۳۰ روزه مقدار زیر را در `.env` تغییر دهید:

```dotenv
LOG_RETENTION_DAYS=30
```

سپس policy و پاک‌سازی را دوباره اعمال کنید:

```bash
docker compose up -d --force-recreate setup log-cleanup
```

حذف توسط ILM و cleanup دوره‌ای است؛ بنابراین ممکن است چند ساعت پس از پایان بازه انجام شود.

## محل ذخیره‌سازی داده‌ها

| داده | مسیر یا نام |
| --- | --- |
| دادهٔ Elasticsearch | `./elasticsearch/data` |
| دادهٔ Kibana | `./kibana/data` |
| آرشیو روزانه | `./logs/<service>-YYYY.MM.dd.ndjson` |
| ایندکس رخدادها | `docker-logs-<service>-YYYY.MM.dd` |

مسیرهای runtime و `.env` در `.gitignore` قرار دارند. حذف این داده‌ها غیرقابل بازگشت است.

## عملیات روزمره

```bash
# وضعیت سرویس‌ها
docker compose ps

# دنبال‌کردن لاگ همهٔ اجزا
docker compose logs -f

# فقط Logstash یا Filebeat
docker compose logs -f logstash filebeat

# توقف بدون حذف داده‌ها
docker compose down

# اعمال تغییر pipeline و ساخت مجدد Logstash
docker compose up -d --build logstash
```

## عیب‌یابی

| مسئله | بررسی |
| --- | --- |
| Kibana بالا نمی‌آید | `docker compose logs setup kibana` را بررسی کنید و از صحت رمزها مطمئن شوید. |
| لاگ سرویس دریافت نمی‌شود | وجود `elk_logs: "true"` و اجرای `docker compose logs filebeat` را بررسی کنید. |
| رخدادها در Kibana دیده نمی‌شوند | `docker compose logs logstash` را بررسی کنید و Data View با الگوی `docker-logs-*` بسازید. |
| retention اعمال نشده است | مقدار صحیح و مثبت `LOG_RETENTION_DAYS` را بررسی و `setup` و `log-cleanup` را recreate کنید. |

## ملاحظات امنیتی

- `.env` حاوی رمز است؛ هرگز آن را commit یا در کانال عمومی ارسال نکنید.
- برای محیط production از رمزهای یکتا و قوی استفاده کنید و رمزهای نمونه را تغییر دهید.
- Kibana را بدون TLS، فایروال و کنترل دسترسی روی اینترنت عمومی منتشر نکنید.
- Filebeat به Docker socket به‌صورت فقط‌خواندنی دسترسی دارد؛ این استک را فقط در محیط‌های مورداعتماد اجرا کنید.
- حساب `elastic` مدیریتی است؛ برنامه‌ها نباید با آن به Elasticsearch متصل شوند.

## ساختار پروژه

```text
.
├── docker-compose.yml
├── Dockerfile
├── .env.example
├── filebeat/filebeat.yml
├── logstash/pipeline/logstash.conf
└── logs/
```
