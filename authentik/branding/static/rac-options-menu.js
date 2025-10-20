// RAC HTML5 Menu de Opciones - Estilo Citrix/Kasm
// Se inyecta en la sesión RAC HTML5 activa

(function() {
    'use strict';

    // Solo ejecutar si estamos en una sesión RAC HTML5
    if (!window.location.href.includes('/if/rac/') && !document.querySelector('canvas')) {
        return;
    }

    // Crear CSS para el menú
    const menuCSS = `
        #rac-options-menu {
            position: fixed;
            top: 10px;
            right: 10px;
            z-index: 9999;
            background: rgba(0, 0, 0, 0.9);
            border: 1px solid #333;
            border-radius: 8px;
            padding: 0;
            min-width: 200px;
            font-family: Arial, sans-serif;
            font-size: 14px;
            box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
            display: none;
        }

        #rac-menu-toggle {
            position: fixed;
            top: 10px;
            right: 10px;
            z-index: 10000;
            background: linear-gradient(135deg, #1d4ed8, #3b82f6);
            color: white;
            border: none;
            border-radius: 50%;
            width: 45px;
            height: 45px;
            cursor: pointer;
            font-size: 16px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
            transition: all 0.3s ease;
        }

        #rac-menu-toggle:hover {
            background: linear-gradient(135deg, #3b82f6, #60a5fa);
            transform: scale(1.05);
        }

        .rac-menu-header {
            background: linear-gradient(135deg, #1d4ed8, #3b82f6);
            color: white;
            padding: 12px 15px;
            margin: 0;
            border-radius: 8px 8px 0 0;
            font-weight: bold;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .rac-menu-header .logo {
            font-size: 16px;
            font-weight: bold;
        }

        .rac-menu-item {
            display: flex;
            align-items: center;
            padding: 12px 15px;
            color: #fff;
            text-decoration: none;
            border-bottom: 1px solid #333;
            cursor: pointer;
            transition: background 0.2s ease;
        }

        .rac-menu-item:hover {
            background: rgba(59, 130, 246, 0.2);
        }

        .rac-menu-item:last-child {
            border-bottom: none;
            border-radius: 0 0 8px 8px;
        }

        .rac-menu-item i {
            margin-right: 10px;
            width: 16px;
            text-align: center;
        }

        .rac-status-bar {
            position: fixed;
            bottom: 10px;
            right: 10px;
            z-index: 9998;
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 8px 12px;
            border-radius: 20px;
            font-size: 12px;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .rac-status-indicator {
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: #22c55e;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }

        .rac-fullscreen-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.5);
            z-index: 9997;
            display: none;
        }
    `;

    // Inyectar CSS
    const style = document.createElement('style');
    style.textContent = menuCSS;
    document.head.appendChild(style);

    // Crear menú HTML
    const menuHTML = `
        <button id="rac-menu-toggle" title="Opciones de sesión">⚙️</button>
        
        <div id="rac-options-menu">
            <div class="rac-menu-header">
                <span class="logo">Neogenesys RAC</span>
                <span>✕</span>
            </div>
            
            <div class="rac-menu-item" data-action="fullscreen">
                <i>⛶</i> Pantalla completa
            </div>
            
            <div class="rac-menu-item" data-action="screenshot">
                <i>📷</i> Captura de pantalla
            </div>
            
            <div class="rac-menu-item" data-action="clipboard">
                <i>📋</i> Portapapeles
            </div>
            
            <div class="rac-menu-item" data-action="settings">
                <i>⚙️</i> Configuración
            </div>
            
            <div class="rac-menu-item" data-action="refresh">
                <i>🔄</i> Actualizar sesión
            </div>
            
            <div class="rac-menu-item" data-action="disconnect" style="color: #ef4444;">
                <i>🚪</i> Cerrar sesión
            </div>
        </div>

        <div class="rac-status-bar">
            <div class="rac-status-indicator"></div>
            <span>Conectado - Neogenesys RAC</span>
            <span id="rac-timer">00:00</span>
        </div>

        <div class="rac-fullscreen-overlay" id="rac-overlay"></div>
    `;

    // Agregar menú al body
    document.body.insertAdjacentHTML('beforeend', menuHTML);

    // Variables del menú
    const menuToggle = document.getElementById('rac-menu-toggle');
    const optionsMenu = document.getElementById('rac-options-menu');
    const overlay = document.getElementById('rac-overlay');
    let menuVisible = false;
    let sessionStartTime = Date.now();

    // Función para mostrar/ocultar menú
    function toggleMenu() {
        menuVisible = !menuVisible;
        optionsMenu.style.display = menuVisible ? 'block' : 'none';
        overlay.style.display = menuVisible ? 'block' : 'none';
    }

    // Event listeners
    menuToggle.addEventListener('click', toggleMenu);
    
    overlay.addEventListener('click', () => {
        if (menuVisible) toggleMenu();
    });

    // Cerrar menú con header X
    document.querySelector('.rac-menu-header span:last-child').addEventListener('click', toggleMenu);

    // Acciones del menú
    document.querySelectorAll('.rac-menu-item').forEach(item => {
        item.addEventListener('click', function() {
            const action = this.getAttribute('data-action');
            handleMenuAction(action);
            toggleMenu();
        });
    });

    // Manejar acciones del menú
    function handleMenuAction(action) {
        switch(action) {
            case 'fullscreen':
                if (document.fullscreenElement) {
                    document.exitFullscreen();
                } else {
                    document.documentElement.requestFullscreen();
                }
                break;
                
            case 'screenshot':
                takeScreenshot();
                break;
                
            case 'clipboard':
                openClipboardDialog();
                break;
                
            case 'settings':
                openSettingsDialog();
                break;
                
            case 'refresh':
                if (confirm('¿Desea actualizar la sesión? Esto puede interrumpir el trabajo actual.')) {
                    window.location.reload();
                }
                break;
                
            case 'disconnect':
                if (confirm('¿Está seguro de que desea cerrar la sesión?')) {
                    // Redirigir al dashboard principal
                    window.location.href = '/if/user/';
                }
                break;
        }
    }

    // Función para captura de pantalla
    function takeScreenshot() {
        const canvas = document.querySelector('canvas');
        if (canvas) {
            const link = document.createElement('a');
            link.download = `neogenesys-rac-${new Date().toISOString().slice(0,19)}.png`;
            link.href = canvas.toDataURL();
            link.click();
        } else {
            alert('No se pudo capturar la pantalla en este momento.');
        }
    }

    // Diálogo de portapapeles
    function openClipboardDialog() {
        const clipboardHTML = `
            <div style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); 
                        background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);
                        z-index: 10001; min-width: 400px;">
                <h3 style="margin: 0 0 15px 0; color: #333;">Portapapeles</h3>
                <textarea id="clipboard-text" style="width: 100%; height: 150px; margin-bottom: 15px; 
                         padding: 10px; border: 1px solid #ddd; border-radius: 4px; resize: vertical;"
                         placeholder="Pegue aquí el texto para enviar al escritorio remoto..."></textarea>
                <div style="text-align: right;">
                    <button onclick="this.closest('div').remove()" 
                            style="margin-right: 10px; padding: 8px 16px; background: #6b7280; color: white; 
                                   border: none; border-radius: 4px; cursor: pointer;">Cancelar</button>
                    <button onclick="sendClipboard()" 
                            style="padding: 8px 16px; background: #1d4ed8; color: white; 
                                   border: none; border-radius: 4px; cursor: pointer;">Enviar</button>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('beforeend', clipboardHTML);
    }

    // Función global para enviar portapapeles
    window.sendClipboard = function() {
        const text = document.getElementById('clipboard-text').value;
        if (text) {
            // Aquí se integraría con la API de RAC para enviar texto
            navigator.clipboard.writeText(text).then(() => {
                alert('Texto copiado al portapapeles local.');
            }).catch(() => {
                alert('Texto preparado para envío.');
            });
        }
        document.querySelector('#clipboard-text').closest('div').remove();
    };

    // Diálogo de configuración
    function openSettingsDialog() {
        const settingsHTML = `
            <div style="position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); 
                        background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 20px rgba(0,0,0,0.3);
                        z-index: 10001; min-width: 350px;">
                <h3 style="margin: 0 0 15px 0; color: #333;">Configuración de sesión</h3>
                
                <div style="margin-bottom: 15px;">
                    <label style="display: block; margin-bottom: 5px; font-weight: bold;">Calidad de video:</label>
                    <select style="width: 100%; padding: 8px; border: 1px solid #ddd; border-radius: 4px;">
                        <option value="high">Alta calidad</option>
                        <option value="medium" selected>Calidad media</option>
                        <option value="low">Baja calidad</option>
                    </select>
                </div>
                
                <div style="margin-bottom: 15px;">
                    <label style="display: flex; align-items: center;">
                        <input type="checkbox" checked style="margin-right: 8px;">
                        Habilitar sonido
                    </label>
                </div>
                
                <div style="margin-bottom: 15px;">
                    <label style="display: flex; align-items: center;">
                        <input type="checkbox" style="margin-right: 8px;">
                        Mostrar estadísticas de conexión
                    </label>
                </div>
                
                <div style="text-align: right;">
                    <button onclick="this.closest('div').remove()" 
                            style="margin-right: 10px; padding: 8px 16px; background: #6b7280; color: white; 
                                   border: none; border-radius: 4px; cursor: pointer;">Cancelar</button>
                    <button onclick="this.closest('div').remove()" 
                            style="padding: 8px 16px; background: #1d4ed8; color: white; 
                                   border: none; border-radius: 4px; cursor: pointer;">Guardar</button>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('beforeend', settingsHTML);
    }

    // Actualizar timer de sesión
    function updateTimer() {
        const elapsed = Math.floor((Date.now() - sessionStartTime) / 1000);
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        const timerElement = document.getElementById('rac-timer');
        if (timerElement) {
            timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
        }
    }

    // Actualizar timer cada segundo
    setInterval(updateTimer, 1000);

    // Atajos de teclado
    document.addEventListener('keydown', function(e) {
        // Ctrl+Alt+M para abrir menú
        if (e.ctrlKey && e.altKey && e.key === 'm') {
            e.preventDefault();
            toggleMenu();
        }
        
        // Ctrl+Alt+D para desconectar
        if (e.ctrlKey && e.altKey && e.key === 'd') {
            e.preventDefault();
            if (confirm('¿Está seguro de que desea cerrar la sesión?')) {
                window.location.href = '/if/user/';
            }
        }
        
        // F11 para pantalla completa
        if (e.key === 'F11') {
            e.preventDefault();
            if (document.fullscreenElement) {
                document.exitFullscreen();
            } else {
                document.documentElement.requestFullscreen();
            }
        }
    });

    console.log('🎮 Neogenesys RAC Menu de Opciones cargado exitosamente!');
    console.log('💡 Atajos de teclado:');
    console.log('   • Ctrl+Alt+M: Abrir/cerrar menú');
    console.log('   • Ctrl+Alt+D: Desconectar sesión');
    console.log('   • F11: Pantalla completa');

})();