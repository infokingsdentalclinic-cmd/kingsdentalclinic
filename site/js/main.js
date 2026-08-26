// Mobile menu toggle
const hamburger = document.getElementById('hamburger');
const mobileMenu = document.getElementById('mobileMenu');

if (hamburger && mobileMenu) {
  hamburger.addEventListener('click', () => {
    mobileMenu.classList.toggle('open');
  });

  document.addEventListener('click', (e) => {
    if (!hamburger.contains(e.target) && !mobileMenu.contains(e.target)) {
      mobileMenu.classList.remove('open');
    }
  });
}

// Fade-in on scroll
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('visible');
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });

document.querySelectorAll('.fade-in').forEach(el => observer.observe(el));

// Floating CTA — slide up after scrolling past hero
const floatCta = document.getElementById('floatCta');
const floatClose = document.getElementById('floatClose');
let floatDismissed = false;

if (floatCta) {
  window.addEventListener('scroll', () => {
    if (floatDismissed) return;
    if (window.scrollY > 500) {
      floatCta.classList.add('float-cta--visible');
    } else {
      floatCta.classList.remove('float-cta--visible');
    }
  }, { passive: true });
}
if (floatClose) {
  floatClose.addEventListener('click', () => {
    floatDismissed = true;
    floatCta.classList.remove('float-cta--visible');
  });
}

// Contact form submission — sends to Netlify Forms (notifications configured in Netlify dashboard)
const form = document.querySelector('form[name="contact"]');
if (form) {
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const btn = form.querySelector('button[type="submit"]');
    const originalText = btn.textContent;
    btn.disabled = true;

    fetch('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(new FormData(form)).toString(),
    })
      .then((res) => {
        if (!res.ok) throw new Error('Form submission failed: ' + res.status);
        btn.textContent = 'Message sent!';
        btn.style.background = 'var(--green)';
        setTimeout(() => {
          btn.textContent = originalText;
          btn.disabled = false;
          btn.style.background = '';
          form.reset();
        }, 4000);
      })
      .catch(() => {
        btn.textContent = 'Something went wrong — please call us';
        btn.disabled = false;
      });
  });
}

// Pricing page email gate — unlocks fee guide + PDF download,
// notifies the clinic via Netlify Forms (same mechanism as the contact form).
const pricingGate = document.getElementById('pricingGate');
const pricingContent = document.getElementById('pricingContent');
const pricingForm = document.querySelector('form[name="price-list-request"]');

function unlockPricing() {
  if (pricingGate) pricingGate.style.display = 'none';
  if (pricingContent) pricingContent.style.display = '';
}

if (pricingGate && pricingContent) {
  try {
    if (localStorage.getItem('kdc_pricing_unlocked') === 'true') {
      unlockPricing();
    }
  } catch (err) {
    // localStorage unavailable (private browsing etc.) — gate stays visible, which is fine.
  }
}

if (pricingForm) {
  pricingForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const btn = pricingForm.querySelector('button[type="submit"]');
    const originalText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Loading…';

    fetch('/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(new FormData(pricingForm)).toString(),
    })
      .then((res) => {
        if (!res.ok) throw new Error('Form submission failed: ' + res.status);
        try { localStorage.setItem('kdc_pricing_unlocked', 'true'); } catch (err) {}
        btn.textContent = originalText;
        btn.disabled = false;
        unlockPricing();
      })
      .catch(() => {
        btn.textContent = 'Something went wrong — please call us';
        btn.disabled = false;
      });
  });
}
