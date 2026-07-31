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

// Contact form submission (basic — wire up to a backend or Netlify Forms as needed)
const form = document.querySelector('form[name="contact"]');
if (form) {
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    const btn = form.querySelector('button[type="submit"]');
    btn.textContent = 'Message sent!';
    btn.disabled = true;
    btn.style.background = 'var(--green)';
    setTimeout(() => {
      btn.textContent = 'Send Message';
      btn.disabled = false;
      btn.style.background = '';
      form.reset();
    }, 4000);
  });
}
