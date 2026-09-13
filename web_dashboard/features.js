/**
 * features.js — AeroSense Edge Dashboard Feature Modules
 * =======================================================
 * Powers all 6 standout feature panels on the web dashboard.
 * Each feature is self-contained and fetches its own data independently.
 * Falls back gracefully to simulated data when the edge node is offline.
 *
 * Features:
 *   1. Health Exposure Engine         /api/health-exposure
 *   2. Safe Window Activity Planner   /api/safe-windows
 *   3. Source DNA Timeline            /api/source-timeline
 *   4. Compliance Streak Tracker      /api/streak
 *   5. Smart Daily Briefing           /api/daily-briefing
 *   6. Anomaly Incident Log           /api/incidents
 */

/* ─── Constants ────────────────────────────────────────────────────────────── */
const BASE_URL = (window._aeroBaseUrl || 'http://localhost:8090');

const SOURCE_COLORS = {
  'Clean Baseline':    '#10B981',
  'Traffic Exhaust':   '#F97316',
  'Garbage Burning':   '#EF4444',
  'Construction Dust': '#EAB308',
  'Cooking Smoke':     '#8B5CF6',
  'Crop Residue':      '#DC2626',
};

function aqiToColor(aqi) {
  if (aqi <= 50)  return '#10B981';
  if (aqi <= 100) return '#84CC16';
  if (aqi <= 150) return '#EAB308';
  if (aqi <= 200) return '#F97316';
  if (aqi <= 300) return '#EF4444';
  return '#7C3AED';
}

function riskColor(level) {
  const map = { LOW: '#10B981', MODERATE: '#84CC16', ELEVATED: '#EAB308', HIGH: '#F97316', SEVERE: '#EF4444', HAZARDOUS: '#7C3AED' };
  return map[level] || '#10B981';
}

async function apiFetch(path, fallback) {
  try {
    const r = await fetch(`${BASE_URL}${path}`, { signal: AbortSignal.timeout(4000) });
    if (r.ok) return await r.json();
  } catch (_) {}
  return fallback;
}

/* ─── Template mounting ──────────────────────────────────────────────────── */
function mountTemplate(templateId) {
  const tpl = document.getElementById(templateId);
  if (!tpl) return null;
  const clone = tpl.content.cloneNode(true);
  const container = document.getElementById('feature-panels-container');
  if (container) container.appendChild(clone);
  return container ? container.lastElementChild : null;
}

/* ══════════════════════════════════════════════════════════════════════════
   FEATURE 5: Smart Daily Briefing
══════════════════════════════════════════════════════════════════════════ */
async function renderDailyBriefing() {
  mountTemplate('tpl-briefing');

  const hour = new Date().getHours();
  const isMorning = hour >= 4 && hour < 14;
  const fallback = {
    type: isMorning ? 'MORNING' : 'EVENING',
    headline: isMorning
      ? 'Good morning! Clean air today — AQI 38. Perfect conditions for outdoor activities.'
      : 'Evening Summary: AQI 45 · WHO compliance 85% · <0.1 cigarette equivalent today',
    briefing_text: 'Air quality is excellent. Conditions expected to remain stable today.',
    key_actions: [
      '🏃 Ideal conditions for outdoor jogging and sports all morning',
      '🪟 Open windows for maximum natural cross-ventilation',
      '🌿 Great air quality day overall',
    ],
    risk_level: 'LOW', risk_emoji: '✅', current_aqi: 38,
    current_source: 'Clean Baseline', forecast_trend: 'STABLE',
    community_alert: null,
    generated_at: new Date().toISOString(),
  };

  const d = await apiFetch('/api/daily-briefing', fallback);
  const c = riskColor(d.risk_level || 'LOW');

  const header = document.getElementById('briefing-header-strip');
  if (header) header.style.background = `linear-gradient(90deg,${c}28 0%,transparent 100%)`;

  const timeIcon = document.getElementById('briefing-time-icon');
  if (timeIcon) timeIcon.textContent = (d.type === 'MORNING') ? '🌅' : '🌙';

  const typeLabel = document.getElementById('briefing-type-label');
  if (typeLabel) typeLabel.textContent = `${d.type} BRIEFING`;

  const genAt = document.getElementById('briefing-generated-at');
  if (genAt && d.generated_at) genAt.textContent = d.generated_at.slice(11, 16);

  const badge = document.getElementById('briefing-risk-badge');
  if (badge) {
    badge.textContent = `${d.risk_emoji || '✅'} ${d.risk_level || 'LOW'}`;
    badge.style.cssText += `;background:${c}26;border-color:${c}60;color:${c}`;
  }

  const alert = document.getElementById('briefing-community-alert');
  if (alert) {
    if (d.community_alert) { alert.textContent = d.community_alert; alert.style.display = 'block'; }
    else alert.style.display = 'none';
  }

  const hl = document.getElementById('briefing-headline');
  if (hl) hl.textContent = d.headline || '';

  const txt = document.getElementById('briefing-text');
  if (txt) txt.textContent = d.briefing_text || '';

  const actions = document.getElementById('briefing-actions');
  if (actions && Array.isArray(d.key_actions)) {
    actions.innerHTML = '';
    d.key_actions.forEach(a => {
      const li = document.createElement('li');
      li.textContent = a;
      li.style.cssText = `font-size:0.77rem;color:var(--text-secondary);padding:0.25rem 0;display:flex;align-items:flex-start;gap:0.4rem;line-height:1.4;`;
      actions.appendChild(li);
    });
  }
}

/* ══════════════════════════════════════════════════════════════════════════
   FEATURE 1: Health Exposure Engine
══════════════════════════════════════════════════════════════════════════ */
async function renderHealthExposure() {
  mountTemplate('tpl-health');

  const fallback = {
    cigarette_equivalent: 0.8, health_points_delta: -12,
    who_compliance_pct: 68.0, compliant_hours: 10, hours_monitored: 14,
    lung_load_score: 45, avg_pm25_today: 28.3,
    exposure_narrative: "Today's exposure ≈ 0.8 cigarettes. WHO compliance 68%. Peak at 08:00 (Traffic Exhaust).",
    hourly_breakdown: [],
  };

  const d = await apiFetch('/api/health-exposure', fallback);
  const load = Math.min(100, d.lung_load_score || 0);
  const CIRC = 238;  // 2πr where r=38
  const dash = (load / 100) * CIRC;
  const arcColor = load > 70 ? '#EF4444' : load > 40 ? '#F97316' : '#10B981';

  const arc = document.getElementById('lung-load-arc');
  if (arc) { arc.style.strokeDasharray = `${dash.toFixed(1)} ${CIRC}`; arc.style.stroke = arcColor; }

  const pctEl = document.getElementById('lung-load-pct');
  if (pctEl) pctEl.textContent = `${load}%`;

  const hp = d.health_points_delta || 0;
  const hpBadge = document.getElementById('health-hp-badge');
  if (hpBadge) {
    hpBadge.textContent = `${hp >= 0 ? '+' : ''}${hp} HP today`;
    const hc = hp < 0 ? '#EF4444' : '#10B981';
    hpBadge.style.cssText += `;background:${hc}26;border-color:${hc}60;color:${hc}`;
  }

  const cig = document.getElementById('health-cig');
  if (cig) {
    const v = (d.cigarette_equivalent || 0).toFixed(1);
    cig.textContent = `${v} cigs`;
    cig.style.color = d.cigarette_equivalent >= 2 ? '#EF4444' : d.cigarette_equivalent >= 1 ? '#F97316' : '#10B981';
  }

  const comp = document.getElementById('health-compliance');
  if (comp) {
    const v = (d.who_compliance_pct || 100).toFixed(0);
    comp.textContent = `${v}%`;
    comp.style.color = d.who_compliance_pct >= 80 ? '#10B981' : d.who_compliance_pct >= 60 ? '#EAB308' : '#EF4444';
  }

  const pm = document.getElementById('health-avg-pm25');
  if (pm) pm.textContent = `${(d.avg_pm25_today || 0).toFixed(1)} µg/m³`;

  // Hourly bar chart
  const bars = document.getElementById('health-hourly-bars');
  if (bars && Array.isArray(d.hourly_breakdown) && d.hourly_breakdown.length > 0) {
    bars.innerHTML = '';
    const maxPm = Math.max(...d.hourly_breakdown.map(h => h.pm25 || 0), 1);
    d.hourly_breakdown.forEach(h => {
      const height = Math.max(3, (h.pm25 / maxPm) * 40);
      const color = h.pm25 <= 15 ? '#10B981' : h.pm25 <= 35 ? '#84CC16' : h.pm25 <= 55 ? '#EAB308' : h.pm25 <= 75 ? '#F97316' : '#EF4444';
      const bar = document.createElement('div');
      bar.title = `${h.hour}\nPM2.5: ${h.pm25} µg/m³\n${h.source}`;
      bar.style.cssText = `flex:1;height:${height}px;background:${color};border-radius:2px 2px 0 0;cursor:help;transition:height 1s cubic-bezier(0.4,0,0.2,1);`;
      bars.appendChild(bar);
    });
  }

  const narr = document.getElementById('health-narrative');
  if (narr) narr.textContent = d.exposure_narrative || '';
}

/* ══════════════════════════════════════════════════════════════════════════
   FEATURE 2: Safe Window Activity Planner
══════════════════════════════════════════════════════════════════════════ */
async function renderSafeWindows() {
  mountTemplate('tpl-windows');

  const fallback = { windows: [], ribbon: [], worst_window: {} };
  const d = await apiFetch('/api/safe-windows', fallback);

  // 24h AQI ribbon
  const ribbonEl = document.getElementById('aqi-ribbon');
  if (ribbonEl && Array.isArray(d.ribbon)) {
    ribbonEl.innerHTML = '';
    const nowH = new Date().getHours();
    d.ribbon.forEach(slot => {
      const h = parseInt(slot.hour);
      const div = document.createElement('div');
      div.title = `${slot.hour}\nAQI ${slot.predicted_aqi}\n${slot.label}`;
      div.style.cssText = `
        flex:1;min-width:18px;height:${h === nowH ? '32px' : '28px'};
        background:${slot.color};border-radius:3px;opacity:${h === nowH ? '1' : '0.7'};
        border:${h === nowH ? '2px solid rgba(255,255,255,0.8)' : 'none'};
        cursor:help;transition:all 0.2s;position:relative;
      `;
      ribbonEl.appendChild(div);
    });
  }

  // Activity windows
  const winEl = document.getElementById('activity-windows');
  if (winEl && Array.isArray(d.windows)) {
    winEl.innerHTML = '';
    d.windows.slice(0, 5).forEach(w => {
      const ac = aqiToColor(w.avg_predicted_aqi);
      const div = document.createElement('div');
      div.style.cssText = `display:flex;align-items:center;gap:0.75rem;padding:0.6rem 0.85rem;border-radius:8px;background:${ac}12;border:1px solid ${ac}35;`;
      div.innerHTML = `
        <span style="font-size:1.3rem;">${w.emoji || '🏃'}</span>
        <div style="flex:1;min-width:0;">
          <div style="font-size:0.83rem;font-weight:600;">${w.activity || ''}</div>
          <div style="font-size:0.7rem;color:var(--text-secondary);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${w.from_time || ''}–${w.to_time || ''} · ${w.reason || ''}</div>
        </div>
        <div style="text-align:right;flex-shrink:0;">
          <div style="font-size:0.88rem;font-weight:800;color:${ac};">AQI ${w.avg_predicted_aqi || 0}</div>
          <div style="font-size:0.65rem;color:var(--text-secondary);">${w.confidence || ''}</div>
        </div>
      `;
      winEl.appendChild(div);
    });
  }

  // Worst window
  const ww = d.worst_window || {};
  const wwEl = document.getElementById('worst-window-alert');
  if (wwEl && ww.peak_aqi > 0) {
    wwEl.style.display = 'block';
    wwEl.innerHTML = `⚠️ <strong>Worst Window: ${ww.from || '?'}</strong> — Peak AQI ${ww.peak_aqi}. ${ww.reason || ''}`;
  }
}

/* ══════════════════════════════════════════════════════════════════════════
   FEATURE 3: Source DNA Timeline
══════════════════════════════════════════════════════════════════════════ */
async function renderSourceTimeline() {
  mountTemplate('tpl-timeline');

  const fallback = { timeline: [], source_distribution: {}, cleanest_hour: null, worst_hour: null };
  const d = await apiFetch('/api/source-timeline?hours=24', fallback);

  // DNA strand
  const strand = document.getElementById('dna-strand');
  if (strand && Array.isArray(d.timeline)) {
    strand.innerHTML = '';
    d.timeline.forEach(slot => {
      const c = SOURCE_COLORS[slot.source] || '#6B7280';
      const div = document.createElement('div');
      div.title = `${slot.hour}\n${slot.source}\nAQI ${slot.avg_aqi}\nPM2.5 ${slot.avg_pm25} µg/m³`;
      div.style.cssText = `
        min-width:44px;height:60px;border-radius:8px;
        background:${c}28;border:1px solid ${c}55;
        display:flex;flex-direction:column;align-items:center;justify-content:center;
        gap:2px;cursor:help;transition:transform 0.2s;flex-shrink:0;
      `;
      div.innerHTML = `<span style="font-size:1.1rem;">${slot.emoji || '🌿'}</span><span style="font-size:0.6rem;color:rgba(255,255,255,0.6);">${slot.hour}</span><span style="font-size:0.65rem;font-weight:700;color:${c};">${slot.avg_aqi}</span>`;
      div.addEventListener('mouseenter', () => div.style.transform = 'scale(1.08)');
      div.addEventListener('mouseleave', () => div.style.transform = 'scale(1)');
      strand.appendChild(div);
    });
  }

  // Source composition bar
  const compBar = document.getElementById('source-comp-bar');
  const legend = document.getElementById('source-legend');
  const dist = d.source_distribution || {};
  const total = Object.values(dist).reduce((a, b) => a + b, 0);
  if (compBar && total > 0) {
    compBar.innerHTML = '';
    if (legend) legend.innerHTML = '';
    Object.entries(dist).forEach(([src, count]) => {
      const frac = count / total;
      const c = SOURCE_COLORS[src] || '#6B7280';
      const seg = document.createElement('div');
      seg.title = `${src}: ${count}h`;
      seg.style.cssText = `flex:${Math.round(frac * 100)};background:${c}cc;cursor:help;`;
      compBar.appendChild(seg);
      if (legend) {
        const item = document.createElement('div');
        item.style.cssText = `display:flex;align-items:center;gap:4px;font-size:0.7rem;color:var(--text-secondary);`;
        item.innerHTML = `<span style="width:8px;height:8px;border-radius:2px;background:${c};display:inline-block;"></span>${src} (${Math.round(frac * 100)}%)`;
        legend.appendChild(item);
      }
    });
  }

  // Peak badges
  const cleanBadge = document.getElementById('cleanest-badge');
  if (cleanBadge && d.cleanest_hour) {
    cleanBadge.style.display = 'block';
    cleanBadge.textContent = `🌿 Cleanest: ${d.cleanest_hour.hour} (AQI ${d.cleanest_hour.avg_aqi})`;
  }
  const worstBadge = document.getElementById('worst-hour-badge');
  if (worstBadge && d.worst_hour) {
    worstBadge.style.display = 'block';
    worstBadge.textContent = `🔴 Worst: ${d.worst_hour.hour} (AQI ${d.worst_hour.avg_aqi})`;
  }
}

/* ══════════════════════════════════════════════════════════════════════════
   FEATURE 4: Compliance Streak & Leaderboard
══════════════════════════════════════════════════════════════════════════ */
async function renderComplianceStreak() {
  mountTemplate('tpl-streak');

  const fallback = {
    current_streak_days: 7, longest_streak_days: 12,
    today_compliant: true, today_avg_pm25: 11.2,
    last_breach_date: '2026-09-04',
    streak_badges: ['🟢 Active Green Streak', '✨ 3-Day Clean Air Run', '🔥 7-Day WHO Compliant Week'],
    daily_calendar: [],
  };

  const d = await apiFetch('/api/streak', fallback);

  const badge = document.getElementById('streak-today-badge');
  if (badge) {
    badge.textContent = d.today_compliant ? '✅ Today Compliant' : '❌ Non-Compliant';
    const c = d.today_compliant ? '#10B981' : '#EF4444';
    badge.style.cssText += `;background:${c}26;border-color:${c}60;color:${c}`;
  }

  const curr = document.getElementById('streak-current');
  if (curr) curr.textContent = d.current_streak_days || 0;

  const best = document.getElementById('streak-best');
  if (best) best.textContent = d.longest_streak_days || 0;

  const pm25El = document.getElementById('streak-pm25');
  if (pm25El) {
    const v = (d.today_avg_pm25 || 0).toFixed(1);
    pm25El.textContent = v;
    pm25El.style.color = d.today_avg_pm25 <= 15 ? '#10B981' : '#EF4444';
  }

  // Badges
  const badgesEl = document.getElementById('streak-badges');
  if (badgesEl && Array.isArray(d.streak_badges)) {
    badgesEl.innerHTML = '';
    d.streak_badges.forEach(b => {
      const span = document.createElement('span');
      span.textContent = b;
      span.style.cssText = `padding:0.2rem 0.65rem;border-radius:20px;font-size:0.72rem;background:rgba(100,210,255,0.08);border:1px solid rgba(100,210,255,0.2);color:var(--text-secondary);`;
      badgesEl.appendChild(span);
    });
  }

  // Calendar heatmap
  const cal = document.getElementById('streak-calendar');
  if (cal && Array.isArray(d.daily_calendar)) {
    cal.innerHTML = '';
    d.daily_calendar.forEach(day => {
      const c = day.compliant ? '#10B981' : '#EF4444';
      const d_parts = day.date.split('-');
      const dd = d_parts[2] || '?';
      const cell = document.createElement('div');
      cell.title = `${day.date}\nPM2.5: ${day.avg_pm25} µg/m³\nAQI: ${day.avg_aqi}\n${day.compliant ? '✅ Compliant' : '❌ Non-Compliant'}`;
      cell.style.cssText = `width:22px;height:22px;border-radius:4px;background:${c}aa;border:1px solid ${c}60;display:flex;align-items:center;justify-content:center;font-size:8px;font-weight:600;color:rgba(255,255,255,0.85);cursor:help;`;
      cell.textContent = dd;
      cal.appendChild(cell);
    });
  }
}

/* ══════════════════════════════════════════════════════════════════════════
   FEATURE 6: Anomaly Incident Log
══════════════════════════════════════════════════════════════════════════ */
async function renderIncidentLog() {
  mountTemplate('tpl-incidents');

  const fallback = { incidents: [], total_count: 0, unconfirmed_count: 0 };
  const d = await apiFetch('/api/incidents?limit=20', fallback);

  const unconfBadge = document.getElementById('incidents-unconfirmed-badge');
  if (unconfBadge && d.unconfirmed_count > 0) {
    unconfBadge.style.display = 'inline';
    unconfBadge.textContent = `${d.unconfirmed_count} unreviewed`;
  }

  const list = document.getElementById('incidents-list');
  if (!list) return;
  if (!Array.isArray(d.incidents) || d.incidents.length === 0) return;

  list.innerHTML = '';
  d.incidents.forEach(inc => {
    const sevColor = inc.severity === 'CRITICAL' ? '#7C3AED' : inc.severity === 'HIGH' ? '#EF4444' : '#F97316';
    const div = document.createElement('div');
    div.style.cssText = `padding:0.7rem 0.9rem;border-radius:8px;background:${sevColor}10;border:1px solid ${sevColor}30;`;
    div.innerHTML = `
      <div style="display:flex;align-items:center;gap:0.6rem;margin-bottom:0.35rem;">
        <span style="font-size:1rem;">${inc.severity === 'CRITICAL' ? '☠️' : inc.severity === 'HIGH' ? '⚠️' : '🔔'}</span>
        <div style="flex:1;">
          <div style="font-size:0.83rem;font-weight:700;">${inc.label || inc.type}</div>
          <div style="font-size:0.7rem;color:var(--text-secondary);">${inc.date_str || ''} at ${inc.time_str || ''}</div>
        </div>
        <span style="font-size:0.7rem;font-weight:700;color:${sevColor};padding:0.15rem 0.5rem;border-radius:20px;background:${sevColor}20;">${inc.severity}</span>
      </div>
      <div style="display:flex;gap:1.25rem;font-size:0.72rem;color:var(--text-secondary);">
        <span>📈 +${inc.magnitude_pct?.toFixed(0) || 0}% spike</span>
        <span>🔍 ${inc.suspected_source || 'Unknown'}</span>
        <span>AQI ${inc.aqi_at_detection || 0}</span>
      </div>
      ${inc.user_confirmation ? `<div style="margin-top:0.35rem;font-size:0.7rem;color:${inc.user_confirmation === 'CONFIRMED' ? '#10B981' : '#6B7280'};">
        ${inc.user_confirmation === 'CONFIRMED' ? '✅ User confirmed' : '🚫 User dismissed'}
      </div>` : `
      <div style="margin-top:0.5rem;display:flex;gap:0.4rem;">
        <button onclick="confirmIncident(${inc.id},'CONFIRMED')" style="padding:0.2rem 0.7rem;font-size:0.7rem;border-radius:6px;background:#10B98120;border:1px solid #10B98155;color:#10B981;cursor:pointer;">✅ Confirm</button>
        <button onclick="confirmIncident(${inc.id},'DISMISSED')" style="padding:0.2rem 0.7rem;font-size:0.7rem;border-radius:6px;background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.15);color:var(--text-secondary);cursor:pointer;">Dismiss</button>
      </div>`}
    `;
    list.appendChild(div);
  });
}

/* Global incident confirmation handler (called by inline onclick) */
async function confirmIncident(id, status) {
  try {
    await fetch(`${BASE_URL}/api/incidents/confirm`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id, status }),
    });
    // Refresh incident log
    const list = document.getElementById('incidents-list');
    if (list) list.innerHTML = '<div style="text-align:center;padding:1rem;color:var(--text-secondary);">Refreshing…</div>';
    await renderIncidentLog();
  } catch (_) {}
}

/* ─── Bootstrap: mount all panels when DOM is ready ────────────────────── */
document.addEventListener('DOMContentLoaded', async () => {
  // Slight stagger so panels animate in sequence
  await renderDailyBriefing();
  setTimeout(renderHealthExposure, 200);
  setTimeout(renderSafeWindows,    400);
  setTimeout(renderSourceTimeline, 600);
  setTimeout(renderComplianceStreak, 800);
  setTimeout(renderIncidentLog,    1000);
});
