const RESOURCE_NAME = GetParentResourceName();
const BUILDER = {
    visible: false,
    category: 'props',
    modelName: '',
    objectCount: 0
};

let CATALOG = { props: [], vehicles: [], objectives: [] };

window.addEventListener('message', function(e) {
    if (e.data && e.data.action === 'builderCatalog') {
        CATALOG = e.data.catalog;
        renderCategories();
        renderCatalog();
    }
});

const TAB_DEFS = [
    { id: 'props',      icon: '\u25A0', label: 'PROPS' },
    { id: 'vehicles',   icon: '\u25B6', label: 'VEHICLES' },
    { id: 'objectives', icon: '\u25C9', label: 'OBJS' },
    { id: 'spawns',     icon: '\u2691', label: 'SPAWNS' }
];

function sendNUI(action, data) {
    fetch('https://' + RESOURCE_NAME + '/' + action, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {})
    });
}

function sendEditorAction(action, data) {
    sendNUI('editorAction', { action: action, data: data || {} });
}

// Category tabs

function renderCategories() {
    const container = document.getElementById('bldrCats');
    if (!container) return;
    let html = '';
    for (let i = 0; i < TAB_DEFS.length; i++) {
        const tab = TAB_DEFS[i];
        const activeClass = BUILDER.category === tab.id ? ' active' : '';
        html += '<div class="sidebar-cat' + activeClass + '" onclick="switchCategory(\'' + tab.id + '\')">' + tab.icon + ' ' + tab.label + '</div>';
    }
    container.innerHTML = html;
}

function switchCategory(cat) {
    BUILDER.category = cat;
    document.getElementById('bldrSearch').value = '';
    renderCategories();
    renderCatalog();
}

// Model list

function renderCatalog() {
    const list = document.getElementById('bldrList');
    if (!list) return;

    if (BUILDER.category === 'spawns') {
        list.innerHTML =
            '<div class="sidebar-item" onclick="sendEditorAction(\'PLACE_SPAWN\',{side:\'team1\'})">' +
                '<div class="item-tag" style="color:#32ff32">T1</div>' +
                '<div class="item-name">Team 1 Spawn</div>' +
            '</div>' +
            '<div class="sidebar-item" onclick="sendEditorAction(\'PLACE_SPAWN\',{side:\'team2\'})">' +
                '<div class="item-tag" style="color:#3278ff">T2</div>' +
                '<div class="item-name">Team 2 Spawn</div>' +
            '</div>';
        return;
    }

    let items = CATALOG[BUILDER.category] || [];
    const query = (document.getElementById('bldrSearch').value || '').toLowerCase();

    if (query) {
        items = items.filter(function(i) {
            return i.n.toLowerCase().indexOf(query) !== -1 || i.t.toLowerCase().indexOf(query) !== -1;
        });
    }

    const customInput = (BUILDER.category === 'props' || BUILDER.category === 'vehicles')
        ? '<div style="padding:6px 14px">' +
            '<input id="bldCustomModel" placeholder="Or type model name..." ' +
                'style="width:100%;padding:6px 8px;background:rgba(0,0,0,0.45);border:1px solid rgba(255,255,255,0.12);border-radius:4px;color:#ccc;font-family:Share Tech Mono,monospace;font-size:0.72rem;outline:none" ' +
                'onkeydown="if(event.key===\'Enter\'){var v=document.getElementById(\'bldCustomModel\').value;if(v){spawnModel(v);document.getElementById(\'bldCustomModel\').value=\'\';}}">' +
        '</div>'
        : '';

    if (!items.length) {
        list.innerHTML = customInput + '<div style="color:#555;padding:20px;text-align:center;font-size:0.68rem">No matches</div>';
        return;
    }

    list.innerHTML = customInput + items.map(function(i) {
        return '<div class="sidebar-item" onclick="spawnModel(\'' + i.n + '\')">' +
            '<div class="item-tag">' + i.t + '</div>' +
            '<div class="item-name">' + i.n + '</div>' +
        '</div>';
    }).join('');
}

function spawnModel(name) {
    sendEditorAction('SPAWN_MODEL', { model: name });
    BUILDER.modelName = name;
    const el = document.getElementById('builderModelName');
    if (el) el.textContent = name.toUpperCase();
    const info = document.getElementById('bldrInfoBody');
    if (info) info.innerHTML = '<div style="color:#e8a838;font-size:0.72rem">Spawned:</div><div style="color:#5ba4f0;font-size:0.68rem;word-break:break-all;margin-top:3px">' + name + '</div>';
}

// Sidebar toggle

function toggleSidebar() {
    const sidebar = document.getElementById('bldrSidebar');
    const toggle = document.getElementById('bldrToggle');
    if (!sidebar || !toggle) return;
    sidebar.classList.toggle('collapsed');
    toggle.innerHTML = sidebar.classList.contains('collapsed') ? '&#x25B6;' : '&#x25C0;';
}

// Objective editor

function updateObjective(idx) {
    const nameEl = document.getElementById('objName');
    const typeEl = document.getElementById('objType');
    const radiusEl = document.getElementById('objRadius');
    const rateEl = document.getElementById('objRate');
    const bonusEl = document.getElementById('objBonus');
    const bonus = parseFloat(bonusEl ? bonusEl.value : '');
    sendEditorAction('UPDATE_OBJ', {
        idx: idx,
        name: nameEl ? nameEl.value : '',
        type: typeEl ? typeEl.value : 'resource',
        radius: parseFloat(radiusEl ? radiusEl.value : '20') || 20,
        captureRate: parseFloat(rateEl ? rateEl.value : '1.5') || 1.5,
        bonus: isNaN(bonus) ? null : bonus
    });
}

// Builder lifecycle messages

window.addEventListener('message', function(e) {
    const data = e.data;
    if (!data || !data.action) return;

    if (data.action === 'builderShow') {
        BUILDER.visible = true;
        document.getElementById('builderShell').classList.add('active');
        renderCategories();
        renderCatalog();

    } else if (data.action === 'builderHide') {
        BUILDER.visible = false;
        document.getElementById('builderShell').classList.remove('active');

    } else if (data.action === 'builderInfo') {
        if (data.modelName !== undefined) {
            BUILDER.modelName = data.modelName || '';
            const el = document.getElementById('builderModelName');
            if (el) el.textContent = BUILDER.modelName.toUpperCase();
        }
        if (data.count !== undefined) {
            BUILDER.objectCount = data.count;
            const el = document.getElementById('builderObjCount');
            if (el) el.textContent = data.count + ' objects';
        }
        if (data.toast) {
            const toast = document.createElement('div');
            toast.textContent = data.toast;
            toast.style.cssText = 'position:fixed;top:50px;left:50%;transform:translateX(-50%);padding:10px 24px;background:rgba(46,204,113,0.95);color:#fff;border-radius:6px;font-family:Share Tech Mono,monospace;font-size:0.75rem;z-index:99999;pointer-events:none';
            document.body.appendChild(toast);
            setTimeout(function() { toast.style.opacity = '0'; setTimeout(function() { toast.remove(); }, 300); }, 2000);
        }
        if (data.objData) {
            const panel = document.getElementById('bldrInfoBody');
            if (!panel) return;
            panel.innerHTML =
                '<div style="font-family:Share Tech Mono,monospace;font-size:0.85rem;color:#e8a838;margin-bottom:8px;text-transform:uppercase;letter-spacing:1px">OBJECTIVE #' + data.objIdx + '</div>' +
                '<input id="objName" value="' + data.objData.name + '" onchange="updateObjective(' + data.objIdx + ')" ' +
                    'style="width:100%;padding:7px 10px;background:rgba(0,0,0,0.5);border:1px solid rgba(255,255,255,0.12);border-radius:4px;color:#ccc;font-size:0.8rem;margin-bottom:7px;font-family:Share Tech Mono,monospace">' +
                '<select id="objType" onchange="updateObjective(' + data.objIdx + ')" ' +
                    'style="width:100%;padding:7px 10px;background:rgba(0,0,0,0.5);border:1px solid rgba(255,255,255,0.12);border-radius:4px;color:#ccc;font-size:0.8rem;margin-bottom:7px;font-family:Share Tech Mono,monospace">' +
                    '<option value="victory"' + (data.objData.type === 'victory' ? ' selected' : '') + '>Victory</option>' +
                    '<option value="resource"' + (data.objData.type === 'resource' ? ' selected' : '') + '>Resource</option>' +
                '</select>' +
                objField('Rad', 'objRadius', data.objData.radius, data.objIdx) +
                objField('Rate', 'objRate', data.objData.captureRate, data.objIdx) +
                objField('Bon', 'objBonus', data.objData.bonus || '', data.objIdx) +
                '<button onclick="updateObjective(' + data.objIdx + ')" ' +
                    'style="width:100%;padding:7px;background:rgba(232,168,56,0.12);border:1px solid rgba(232,168,56,0.4);border-radius:4px;color:#e8a838;font-size:0.75rem;cursor:pointer;font-family:Share Tech Mono,monospace;text-transform:uppercase;letter-spacing:1px" ' +
                    'onmouseover="this.style.background=\'rgba(232,168,56,0.22)\'" ' +
                    'onmouseout="this.style.background=\'rgba(232,168,56,0.12)\'">Update</button>';
        }
    }
});

function objField(label, id, value, idx) {
    return '<div style="display:flex;gap:6px;margin-bottom:5px;align-items:center">' +
        '<span style="color:#888;font-size:0.72rem;min-width:32px">' + label + ':</span>' +
        '<input id="' + id + '" value="' + value + '" onchange="updateObjective(' + idx + ')" ' +
            'style="flex:1;padding:5px 7px;background:rgba(0,0,0,0.5);border:1px solid rgba(255,255,255,0.12);border-radius:3px;color:#ccc;font-size:0.75rem;font-family:Share Tech Mono,monospace">' +
    '</div>';
}

// Screen markers

window.addEventListener('message', function(e) {
    const data = e.data;
    if (!data || !data.type) return;
    if (data.type === 'drawMarkers') {
        const container = document.getElementById('screenMarkers');
        if (!container) return;
        if (!data.markers || !data.markers.length) { container.innerHTML = ''; return; }
        let html = '';
        for (let i = 0; i < data.markers.length; i++) {
            const m = data.markers[i];
            const textColor = m.color === '#ffffff' ? '#000' : '#fff';
            html += '<div class="screen-marker" style="left:' + (m.x * 100) + '%;top:' + (m.y * 100) + '%">' +
                m.icon + '<span style="background:' + m.color + ';color:' + textColor + '">' + m.label + '</span></div>';
        }
        container.innerHTML = html;
    }
});

// Input handling

window.addEventListener('keydown', function(e) {
    if (e.key === 'F10') { e.preventDefault(); sendNUI('toggleAdmin'); }
    if (!BUILDER.visible) return;

    const tag = document.activeElement ? document.activeElement.tagName : '';
    if (tag === 'INPUT' || tag === 'SELECT' || tag === 'TEXTAREA') {
        if (e.key === 'Backspace' || e.key === 'Delete') return;
    }

    const keyMap = {
        'e': 'PICKUP', 'E': 'PICKUP',
        'c': 'CLONE', 'C': 'CLONE',
        'r': 'RESET_HEIGHT', 'R': 'RESET_HEIGHT',
        'Delete': 'DELETE', 'Del': 'DELETE',
        'Backspace': 'EXIT',
        'ArrowLeft': 'ROTATE_LEFT', 'ArrowRight': 'ROTATE_RIGHT',
        'Shift': 'SHIFT_DOWN'
    };

    if (keyMap[e.key]) {
        if (e.key === 'Backspace' && !tag) return;
        sendEditorAction(keyMap[e.key]);
    }
});

window.addEventListener('keyup', function(e) {
    if (!BUILDER.visible) return;
    if (e.key === 'Shift' && (!document.activeElement || document.activeElement.tagName !== 'INPUT')) {
        sendEditorAction('SHIFT_UP');
    }
});

window.addEventListener('mousedown', function(e) {
    if (!BUILDER.visible) return;
    let target = e.target;
    while (target) {
        if (target.id === 'bldrSidebar' || target.id === 'bldrInfoPanel' || target.id === 'bldrList') return;
        if (target.classList && target.classList.contains('sidebar-item')) return;
        target = target.parentElement;
    }
    const action = e.button === 0 ? 'CLICK_LEFT' : (e.button === 2 ? 'CLICK_RIGHT' : null);
    if (action) sendEditorAction(action);
});

window.addEventListener('wheel', function(e) {
    if (!BUILDER.visible) return;
    let target = e.target;
    while (target) {
        if (target.classList && (
            target.classList.contains('sidebar-body') ||
            target.classList.contains('panel-body') ||
            target.classList.contains('builder-sidebar') ||
            target.classList.contains('builder-panel'))
        ) return;
        target = target.parentElement;
    }
    sendEditorAction(e.deltaY < 0 ? 'ZOOM_IN' : 'ZOOM_OUT');
}, { passive: true });

renderCategories();
renderCatalog();
