const navbar = document.getElementById('navbar');
const hamburger = document.getElementById('hamburger');
const navLinks = document.getElementById('nav-links');

// Navbar transparency change on scroll
window.onscroll = () => {
    if (window.scrollY > 80) {
        navbar.classList.add('scrolled');
    } else {
        navbar.classList.remove('scrolled');
    }
};

// Hamburger menu toggle
hamburger.onclick = () => {
    navLinks.classList.toggle('active');
};

// Auto-close menu on link click
document.querySelectorAll('.nav-links a').forEach(link => {
    link.onclick = () => navLinks.classList.remove('active');
});