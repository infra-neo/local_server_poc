// Script JavaScript para ocultar elementos de footer de authentik
// Se ejecuta cuando la página se carga

document.addEventListener('DOMContentLoaded', function() {
    // Función para ocultar elementos de footer
    function hideAuthentikFooter() {
        // Selectores CSS para elementos que pueden contener "Desarrollado por authentik"
        const selectors = [
            '.pf-c-login__footer',
            '.ak-footer',
            '.ak-footer-links', 
            'footer[data-ouia-component-type="PF5/Footer"]',
            '.pf-l-bullseye__item .pf-c-login__footer',
            '.pf-c-login__main-footer-band',
            '.ak-login-footer',
            '.pf-c-login__footer-links',
            '.ak-footer-copyright',
            '[data-testid="ak-footer-link"]',
            '.pf-c-login__main-footer-band-item'
        ];
        
        // Ocultar elementos por selector
        selectors.forEach(selector => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(element => {
                element.style.display = 'none !important';
                element.style.visibility = 'hidden !important';
                element.remove(); // Remover completamente del DOM
            });
        });
        
        // Ocultar elementos que contengan texto específico
        const textToHide = [
            'Desarrollado por authentik',
            'Powered by authentik',
            'authentik'
        ];
        
        textToHide.forEach(text => {
            const walker = document.createTreeWalker(
                document.body,
                NodeFilter.SHOW_TEXT,
                null,
                false
            );
            
            let node;
            const nodesToRemove = [];
            
            while (node = walker.nextNode()) {
                if (node.textContent.toLowerCase().includes(text.toLowerCase())) {
                    nodesToRemove.push(node.parentElement);
                }
            }
            
            nodesToRemove.forEach(element => {
                if (element) {
                    element.style.display = 'none !important';
                    element.remove();
                }
            });
        });
        
        // Agregar texto personalizado de Neogenesys
        const loginContainer = document.querySelector('.pf-c-login');
        if (loginContainer) {
            const customFooter = document.createElement('div');
            customFooter.className = 'neogenesys-footer';
            customFooter.innerHTML = '<p style="text-align: center; color: #64748b; font-size: 0.85rem; margin-top: 20px;">Desarrollado por Neogenesys</p>';
            loginContainer.appendChild(customFooter);
        }
    }
    
    // Ejecutar inmediatamente
    hideAuthentikFooter();
    
    // Ejecutar cada 500ms para capturar elementos cargados dinámicamente
    const interval = setInterval(hideAuthentikFooter, 500);
    
    // Detener después de 10 segundos
    setTimeout(() => {
        clearInterval(interval);
    }, 10000);
});

// También ejecutar cuando la página cambie (para SPAs)
if (window.history && window.history.pushState) {
    const originalPushState = window.history.pushState;
    window.history.pushState = function() {
        originalPushState.apply(window.history, arguments);
        setTimeout(hideAuthentikFooter, 100);
    };
}