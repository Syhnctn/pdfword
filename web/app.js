const tabs = Array.from(document.querySelectorAll(".tab"));
const panels = Array.from(document.querySelectorAll("[data-panel]"));
const langButtons = Array.from(document.querySelectorAll(".lang-btn"));

const I18N = {
  tr: {
    meta_description:
      "Only PDF to WORD - Yapay zeka ile PDF dosyalarini duzenlenebilir Word dokumanina donustur.",
    tabs_aria: "Ana sekmeler",
    lang_aria: "Dil secimi",
    brand_title: "Only PDF to WORD",
    brand_subtitle: "AI OCR Platform",
    tab_home: "Ana Sayfa",
    tab_features: "Ozellikler",
    tab_privacy: "Privacy",
    tab_contact: "Iletisim",
    badge_text: "Mobil uygulama ile birebir deneyim",
    hero_title: "Taradigin PDF'leri saniyeler icinde Word'e cevir.",
    hero_lead:
      "Only PDF to WORD; belge yukleme, job takip, indirme ve gecmis akislarini tek ekranda yonetir. Bu site canli mock metriklerle urunun durumunu gosterir.",
    btn_demo: "Canli Demo Akisi",
    btn_privacy: "Privacy Politikasi",
    status_title: "Sistem Durumu",
    metric_docs: "Bugun donusen belge",
    metric_rate: "Basari orani",
    metric_time: "Ortalama sure",
    metric_queue: "Aktif kuyruk",
    metric_time_unit: " sn",
    queue_title: "Canli Donusum Kuyrugu",
    queue_live: "Canli",
    features_title: "Uygulama Ozellikleri",
    feature1_title: "Akilli Yukleme",
    feature1_desc:
      "Coklu PDF sec, upload progress'i satir bazinda izle, istedigin dosyayi aninda kaldir.",
    feature2_title: "Job Polling",
    feature2_desc:
      "Gercek zamanli durum: queued, processing, succeeded, failed. UI otomatik yenilenir.",
    feature3_title: "History + Download",
    feature3_desc:
      "Gecmis donusumleri bolumlu listele, signed URL ile guvenli indir, durum badge'lerini gor.",
    feature4_title: "Supabase Hazir",
    feature4_desc:
      "Edge Functions, Storage, signed upload/download ve worker webhook yapisi ile hazir.",
    privacy_title: "Privacy",
    privacy_intro:
      "Bu uygulama gizlilik odakli tasarlanmistir. Asagidaki maddeler urunun temel veri ilkelerini aciklar:",
    privacy_li1: "Yuklenen dosyalar sadece donusum amaci ile islenir.",
    privacy_li2: "Dosya erisimleri signed URL ile sureli ve yetkili sekilde verilir.",
    privacy_li3: "Kullanici hesap verileri yetkisiz erisime karsi korunur.",
    privacy_li4: "Kullanici talebine gore dosyalar ve gecmis kayitlari silinebilir.",
    privacy_note:
      "Not: Gercek production politikasinda saklama suresi, yasal dayanak ve KVKK/GDPR detaylari ayrica yayinlanir.",
    privacy_contact_label: "Privacy sorulari:",
    contact_title: "Iletisim",
    contact_intro: "Urun, destek veya is birligi icin dogrudan ulasabilirsin:",
    form_name_label: "Ad Soyad",
    form_name_placeholder: "Adinizi yazin",
    form_message_label: "Mesaj",
    form_message_placeholder: "Kisa mesajinizi yazin...",
    form_submit: "Mesaji Hazirla",
    form_feedback:
      "Tesekkurler {name}. Mesajin hazirlandi, lutfen email ile gonder: seyhanceti@gmail.com",
    footer_brand: "Only PDF to WORD",
    last_updated_prefix: "Son guncelleme:",
    state_uploading: "Yukleniyor",
    state_processing: "Isleniyor",
    state_almost_done: "Tamamlanmak uzere",
    state_ready: "Hazir",
  },
  en: {
    meta_description:
      "Only PDF to WORD - Convert scanned PDFs into editable Word documents with AI.",
    tabs_aria: "Main tabs",
    lang_aria: "Language selection",
    brand_title: "Only PDF to WORD",
    brand_subtitle: "AI OCR Platform",
    tab_home: "Home",
    tab_features: "Features",
    tab_privacy: "Privacy",
    tab_contact: "Contact",
    badge_text: "Mobile app level experience",
    hero_title: "Convert scanned PDFs to Word in seconds.",
    hero_lead:
      "Only PDF to WORD manages upload, job tracking, download, and history flows in one place. This site shows live mock metrics for the product.",
    btn_demo: "Live Demo Flow",
    btn_privacy: "Privacy Policy",
    status_title: "System Status",
    metric_docs: "Documents converted today",
    metric_rate: "Success rate",
    metric_time: "Average time",
    metric_queue: "Active queue",
    metric_time_unit: " sec",
    queue_title: "Live Conversion Queue",
    queue_live: "Live",
    features_title: "App Features",
    feature1_title: "Smart Upload",
    feature1_desc:
      "Select multiple PDFs, track upload progress per row, and remove any file instantly.",
    feature2_title: "Job Polling",
    feature2_desc:
      "Real-time states: queued, processing, succeeded, failed. UI updates automatically.",
    feature3_title: "History + Download",
    feature3_desc:
      "Browse grouped history, download securely with signed URLs, and view row-level badges.",
    feature4_title: "Supabase Ready",
    feature4_desc:
      "Built with Edge Functions, Storage, signed upload/download, and worker webhook architecture.",
    privacy_title: "Privacy",
    privacy_intro:
      "This app is designed with privacy by default. The items below summarize the core data principles:",
    privacy_li1: "Uploaded files are processed only for conversion purposes.",
    privacy_li2: "File access is granted through time-limited signed URLs.",
    privacy_li3: "Account data is protected against unauthorized access.",
    privacy_li4: "Files and history can be deleted upon user request.",
    privacy_note:
      "Note: In production policy, retention period, legal basis, and compliance details are documented separately.",
    privacy_contact_label: "Privacy questions:",
    contact_title: "Contact",
    contact_intro: "For product, support, or partnership, contact directly:",
    form_name_label: "Full Name",
    form_name_placeholder: "Type your name",
    form_message_label: "Message",
    form_message_placeholder: "Write your short message...",
    form_submit: "Prepare Message",
    form_feedback:
      "Thanks {name}. Your message draft is ready, please send it via email: seyhanceti@gmail.com",
    footer_brand: "Only PDF to WORD",
    last_updated_prefix: "Last update:",
    state_uploading: "Uploading",
    state_processing: "Processing",
    state_almost_done: "Almost done",
    state_ready: "Ready",
  },
};

const queueSeed = [
  { name: "KUTAHYA_HALK_EGITIM_MERKEZI.pdf", progress: 14, stateKey: "uploading" },
  { name: "Annual_Report_2025.pdf", progress: 62, stateKey: "processing" },
  { name: "Project_Spec_v3.pdf", progress: 92, stateKey: "almost_done" },
];

const queueListEl = document.getElementById("queueList");
const contactForm = document.getElementById("contactForm");
const lastUpdatedEl = document.getElementById("lastUpdated");
const metaDescriptionEl = document.getElementById("metaDescription");

let currentLocale = "tr";

function isLocaleSupported(locale) {
  return locale === "tr" || locale === "en";
}

function t(key) {
  return I18N[currentLocale]?.[key] ?? key;
}

function setLocale(locale) {
  if (!isLocaleSupported(locale)) return;
  currentLocale = locale;
  localStorage.setItem("pdfword_locale", locale);
  applyI18n();
}

function bootLocale() {
  const saved = localStorage.getItem("pdfword_locale");
  if (isLocaleSupported(saved)) {
    currentLocale = saved;
    return;
  }
  currentLocale = "en";
}

function applyI18n() {
  document.documentElement.lang = currentLocale;
  if (metaDescriptionEl) {
    metaDescriptionEl.setAttribute("content", t("meta_description"));
  }

  document.querySelectorAll("[data-i18n]").forEach((element) => {
    const key = element.dataset.i18n;
    element.textContent = t(key);
  });

  document.querySelectorAll("[data-i18n-placeholder]").forEach((element) => {
    const key = element.dataset.i18nPlaceholder;
    element.setAttribute("placeholder", t(key));
  });

  document.querySelectorAll("[data-i18n-aria-label]").forEach((element) => {
    const key = element.dataset.i18nAriaLabel;
    element.setAttribute("aria-label", t(key));
  });

  langButtons.forEach((button) => {
    button.classList.toggle("is-active", button.dataset.lang === currentLocale);
  });

  animateAllMetrics();
  renderQueue();
  updateTimestamp();
}

function renderQueue() {
  if (!queueListEl) return;
  queueListEl.innerHTML = "";
  for (const item of queueSeed) {
    const li = document.createElement("li");
    li.className = "queue-item";
    li.innerHTML = `
      <div class="queue-row">
        <strong>${item.name}</strong>
        <span>${t(`state_${item.stateKey}`)}</span>
      </div>
      <div class="progress"><i style="width:${item.progress}%"></i></div>
    `;
    queueListEl.appendChild(li);
  }
}

function tickQueue() {
  for (const item of queueSeed) {
    const bump = Math.floor(Math.random() * 18);
    item.progress = Math.min(100, item.progress + bump);
    if (item.progress < 40) item.stateKey = "uploading";
    else if (item.progress < 90) item.stateKey = "processing";
    else if (item.progress < 100) item.stateKey = "almost_done";
    else item.stateKey = "ready";
  }
  renderQueue();
}

function setActivePanel(id) {
  const safeId = id || "home";
  const panelExists = panels.some((panel) => panel.id === safeId);
  const targetPanel = panelExists ? safeId : "home";

  for (const panel of panels) {
    panel.classList.toggle("is-active", panel.id === targetPanel);
  }
  for (const tab of tabs) {
    tab.classList.toggle("is-active", tab.dataset.tabTarget === targetPanel);
  }
  const hash = `#${targetPanel}`;
  if (location.hash !== hash) {
    history.replaceState({}, "", hash);
  }
}

tabs.forEach((tab) => {
  tab.addEventListener("click", () => setActivePanel(tab.dataset.tabTarget));
});

langButtons.forEach((button) => {
  button.addEventListener("click", () => setLocale(button.dataset.lang));
});

window.addEventListener("hashchange", () => {
  const next = location.hash.replace("#", "");
  if (next) setActivePanel(next);
});

document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
  anchor.addEventListener("click", (event) => {
    const target = anchor.getAttribute("href")?.replace("#", "");
    if (!target) return;
    if (!panels.some((panel) => panel.id === target)) return;
    event.preventDefault();
    setActivePanel(target);
  });
});

function animateMetric(id, end, suffix = "") {
  const element = document.getElementById(id);
  if (!element) return;
  const duration = 1200;
  const start = performance.now();
  function frame(now) {
    const progress = Math.min(1, (now - start) / duration);
    const value = Math.round(end * progress);
    element.textContent = `${value}${suffix}`;
    if (progress < 1) requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
}

function animateAllMetrics() {
  animateMetric("metricDocs", 1284);
  animateMetric("metricRate", 97, "%");
  animateMetric("metricTime", 6, t("metric_time_unit"));
  animateMetric("metricQueue", queueSeed.length);
}

function updateTimestamp() {
  if (!lastUpdatedEl) return;
  const now = new Date();
  const localeCode = currentLocale === "tr" ? "tr-TR" : "en-US";
  lastUpdatedEl.textContent = `${t("last_updated_prefix")} ${now.toLocaleString(localeCode)}`;
}

function handleContactForm() {
  if (!contactForm) return;
  contactForm.addEventListener("submit", (event) => {
    event.preventDefault();
    const formData = new FormData(contactForm);
    const name = String(formData.get("name") || "").trim();
    const message = String(formData.get("message") || "").trim();
    const feedback = document.getElementById("formFeedback");
    if (!name || !message || !feedback) return;
    feedback.textContent = t("form_feedback").replace("{name}", name);
    contactForm.reset();
  });
}

function init() {
  bootLocale();
  const startTab = location.hash.replace("#", "") || "home";
  setActivePanel(startTab);
  handleContactForm();
  applyI18n();
  setInterval(tickQueue, 1800);
  setInterval(updateTimestamp, 15000);
}

init();
