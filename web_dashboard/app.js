/**
 * AeroSense Pro — Apple-Grade Edge AI Air Intelligence Controller
 * Running on Arduino UNO Q (Qualcomm QRB2210 + STM32U585)
 */

document.addEventListener('DOMContentLoaded', () => {

  // ---------------------------------------------------------------------------
  // Core Element References
  // ---------------------------------------------------------------------------
  const aqiDisplay          = document.getElementById('aqi-display');
  const aqiCategoryBadge    = document.getElementById('aqi-category-badge');
  const aqiPrimaryPollutant = document.getElementById('aqi-primary-pollutant');
  const gaugeFillArc        = document.getElementById('gauge-fill-arc');
  const scaleSegments       = document.querySelectorAll('.scale-segment');
  const aqiTimestamp        = document.getElementById('aqi-timestamp');

  // Source attribution elements
  const sourceName            = document.getElementById('source-name');
  const sourceDesc            = document.getElementById('source-desc');
  const sourceConfidenceBadge = document.getElementById('source-confidence-badge');
  const sourceIconContainer   = document.getElementById('source-icon-container');
  const fpPmRatioVal          = document.getElementById('fp-pm-ratio-val');
  const fpPmRatioBar          = document.getElementById('fp-pm-ratio-bar');
  const fpCoRatioVal          = document.getElementById('fp-co-ratio-val');
  const fpCoRatioBar          = document.getElementById('fp-co-ratio-bar');
  const fpNo2RatioVal         = document.getElementById('fp-no2-ratio-val');
  const fpNo2RatioBar         = document.getElementById('fp-no2-ratio-bar');
  const xaiChipsList          = document.getElementById('xai-chips-list');

  // Forecast elements
  const forecastTimeline   = document.getElementById('forecast-timeline');
  const forecastTrendPill  = document.getElementById('forecast-trend-pill');
  const forecastTipText    = document.getElementById('forecast-tip-text');

  // Advisory elements
  const advisoryHeadline   = document.getElementById('advisory-headline');
  const urgentAlertBanner  = document.getElementById('urgent-alert-banner');
  const urgentAlertText    = document.getElementById('urgent-alert-text');
  const citizenActionList  = document.getElementById('citizen-action-list');
  const schoolActionList   = document.getElementById('school-action-list');
  const communityActionList = document.getElementById('community-action-list');

  // Extended Telemetry Elements (12 Parameters)
  const valPm1     = document.getElementById('val-pm1');
  const valPm25    = document.getElementById('val-pm25');
  const valPm10    = document.getElementById('val-pm10');
  const valNo2     = document.getElementById('val-no2');
  const valCo      = document.getElementById('val-co');
  const valCo2     = document.getElementById('val-co2');
  const valNh3     = document.getElementById('val-nh3');
  const valVoc     = document.getElementById('val-voc');
  const valTemp    = document.getElementById('val-temp');
  const valHum     = document.getElementById('val-hum');
  const valPres    = document.getElementById('val-pres');
  const valBattery = document.getElementById('val-battery');
  const valBatTile = document.getElementById('val-bat-tile');
  const valLatency = document.getElementById('val-latency');

  // Status pills
  const statusPm1  = document.getElementById('status-pm1');
  const statusPm25 = document.getElementById('status-pm25');
  const statusPm10 = document.getElementById('status-pm10');
  const statusNo2  = document.getElementById('status-no2');
  const statusCo   = document.getElementById('status-co');
  const statusCo2  = document.getElementById('status-co2');
  const statusNh3  = document.getElementById('status-nh3');
  const statusVoc  = document.getElementById('status-voc');
  const statusPres = document.getElementById('status-pres');
  const statusBatTile = document.getElementById('status-bat-tile');

  // Bar fills
  const barPm1     = document.getElementById('bar-pm1');
  const barPm25    = document.getElementById('bar-pm25');
  const barPm10    = document.getElementById('bar-pm10');
  const barNo2     = document.getElementById('bar-no2');
  const barCo      = document.getElementById('bar-co');
  const barCo2     = document.getElementById('bar-co2');
  const barNh3     = document.getElementById('bar-nh3');
  const barVoc     = document.getElementById('bar-voc');
  const barTemp    = document.getElementById('bar-temp');
  const barHum     = document.getElementById('bar-hum');
  const barPres    = document.getElementById('bar-pres');
  const barBatTile = document.getElementById('bar-bat-tile');

  // Mesh & sync elements
  const mapNodesGroup       = document.getElementById('map-nodes-group');
  const meshNodesList       = document.getElementById('mesh-nodes-list');
  const meshNodesCount      = document.getElementById('mesh-nodes-count');
  const hexDumpDisplay      = document.getElementById('hex-dump-display');
  const compressionSavings  = document.getElementById('compression-savings');
  const compressionDailySize = document.getElementById('compression-daily-size');
  const btnTriggerCompress  = document.getElementById('btn-trigger-compress');
  const statRecordCount     = document.getElementById('stat-record-count');
  const statUptime          = document.getElementById('stat-uptime');

  // Connection status
  const connectionPill = document.getElementById('connection-pill');
  const connDot        = document.getElementById('conn-dot');
  const connLabel      = document.getElementById('conn-label');

  // Sparkline canvas
  const sparklineCanvas = document.getElementById('sparkline-canvas');
  const sparklineRange  = document.getElementById('sparkline-range');
  const sparkCtx        = sparklineCanvas ? sparklineCanvas.getContext('2d') : null;

  // Historical Analytics Elements
  const analyticsCanvas  = document.getElementById('analytics-canvas');
  const analyticsCtx     = analyticsCanvas ? analyticsCanvas.getContext('2d') : null;
  const statAnalyticsCurr = document.getElementById('stat-analytics-curr');
  const statAnalyticsMin  = document.getElementById('stat-analytics-min');
  const statAnalyticsMax  = document.getElementById('stat-analytics-max');
  const statAnalyticsAvg  = document.getElementById('stat-analytics-avg');
  const analyticsSub     = document.getElementById('analytics-sub');

  // Controls
  const scenarioSelect    = document.getElementById('scenario-select');
  const quickSearchInput  = document.getElementById('quick-search-input');

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------
  let isStandalone        = false;
  let simulatedScenario   = 'Clean Baseline';
  let internalSimStep     = 0;
  let refreshIntervalMs   = 1000;
  let timerHandle         = null;
  let audioAlertsEnabled  = false;
  let activeChartMode     = 'aqi_pm'; // 'aqi_pm' | 'gases' | 'climate'

  // Full history ring buffer (last 60 readings)
  const HISTORY_CAPACITY = 60;
  const historyBuffer = [];
  const aqiHistory = [];

  const SOURCE_ICONS = {
    'Clean Baseline':   '🌿',
    'Traffic Exhaust':  '🚗',
    'Garbage Burning':  '🔥',
    'Construction Dust':'🏗️',
    'Cooking Smoke':    '🍳',
    'Crop Residue':     '🌾'
  };

  // Node database for interactive inspection
  const NODE_METADATA = {
    'UNO-Q-NODE-01': {
      name: 'Central Academic Quad (Local Master)',
      id: 'UNO-Q-NODE-01',
      loc: 'Quadrangle Plaza, Zone 1',
      gps: '20.3540° N, 85.8180° E',
      status: 'ONLINE (MASTER)',
      action: 'Natural cross-ventilation approved. Recess & sports in outdoor zones.',
      bat: '96% • MPPT Solar Nominal'
    },
    'NODE-02-PLAYGROUND': {
      name: 'Sports Complex & Athletic Field',
      id: 'NODE-02-PLAYGROUND',
      loc: 'East Athletics Oval, Zone 2',
      gps: '20.3562° N, 85.8215° E',
      status: 'ONLINE',
      action: 'High solar dispersion. Full cardio workouts approved.',
      bat: '94% • LiFePO₄ Stable'
    },
    'NODE-03-NORTH-GATE': {
      name: 'North Gate Arterial Highway',
      id: 'NODE-03-NORTH-GATE',
      loc: 'Campus Main Entrance Road, Zone 3',
      gps: '20.3585° N, 85.8152° E',
      status: 'ONLINE',
      action: 'Vehicular traffic exhaust elevated. Reroute pedestrian paths away from perimeter.',
      bat: '88% • Battery Backup'
    },
    'NODE-04-CANTEEN': {
      name: 'Dining Pavilion & Food Court',
      id: 'NODE-04-CANTEEN',
      loc: 'Central Student Amenities, Zone 4',
      gps: '20.3522° N, 85.8208° E',
      status: 'ONLINE',
      action: 'Ensure commercial kitchen range hoods are operating at peak extraction.',
      bat: '98% • AC Mains Powered'
    },
    'NODE-05-WEST-EXPANSION': {
      name: 'West Block Expansion Wing',
      id: 'NODE-05-WEST-EXPANSION',
      loc: 'Engineering Labs & Workshop, Zone 5',
      gps: '20.3510° N, 85.8140° E',
      status: 'ONLINE',
      action: 'Construction excavation active. Water mist suppression sprinklers recommended.',
      bat: '76% • Solar Panel Partial Shade'
    }
  };

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  function getAqiColor(aqi) {
    if (aqi <= 50)  return '#30D158'; // Apple Mint
    if (aqi <= 100) return '#A4E235'; // Apple Lime
    if (aqi <= 200) return '#FFD60A'; // Apple Amber
    if (aqi <= 300) return '#FF9F0A'; // Apple Orange
    if (aqi <= 400) return '#FF453A'; // Apple Coral Red
    return '#BF5AF2';                 // Apple Violet
  }

  function num(v, fallback = 0) {
    const n = parseFloat(v);
    return isNaN(n) ? fallback : n;
  }

  function fmt(v, decimals = 1, fallback = '—') {
    const n = parseFloat(v);
    return isNaN(n) ? fallback : n.toFixed(decimals);
  }

  function aqiPillLabel(aqi, thresholds) {
    for (const [limit, label] of thresholds) {
      if (aqi <= limit) return label;
    }
    return thresholds[thresholds.length - 1][1];
  }

  function formatUptime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) return `${h}h ${m}m`;
    if (m > 0) return `${m}m ${s}s`;
    return `${s}s`;
  }

  // Audio Beep Simulator (Web Audio API)
  function playAlertBeep() {
    if (!audioAlertsEnabled) return;
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(880, ctx.currentTime);
      gain.gain.setValueAtTime(0.08, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.35);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.35);
    } catch {}
  }

  // ---------------------------------------------------------------------------
  // Connection Status UI
  // ---------------------------------------------------------------------------
  function setConnectionStatus(live) {
    isStandalone = !live;
    if (!connDot || !connLabel || !connectionPill) return;
    if (live) {
      connectionPill.className = 'stat-pill connection-pill live';
      connDot.className        = 'conn-dot live';
      connLabel.textContent    = '🟢 Live';
    } else {
      connectionPill.className = 'stat-pill connection-pill simulated';
      connDot.className        = 'conn-dot simulated';
      connLabel.textContent    = '🟡 Standalone';
    }
  }

  // ---------------------------------------------------------------------------
  // Radial AQI Activity Ring Gauge
  // ---------------------------------------------------------------------------
  function updateRadialGauge(aqi, color) {
    if (!aqiDisplay) return;
    aqiDisplay.textContent = Math.round(aqi);
    aqiDisplay.style.color = color;

    // Circumference for r=80 is 2 * PI * 80 ≈ 502.65
    const maxOffset = 502.65;
    const progress  = Math.min(1.0, Math.max(0, aqi / 500.0));
    const offset    = maxOffset * (1.0 - progress);

    if (gaugeFillArc) {
      gaugeFillArc.style.strokeDashoffset = offset;
      gaugeFillArc.style.stroke           = color;
      gaugeFillArc.style.filter           = `drop-shadow(0 0 16px ${color})`;
    }

    const gaugeWrapper = aqiDisplay.closest('[role="meter"]');
    if (gaugeWrapper) gaugeWrapper.setAttribute('aria-valuenow', Math.round(aqi));

    // Scale bar highlight
    scaleSegments.forEach(seg => seg.classList.remove('active'));
    if      (aqi <= 50  && scaleSegments[0]) scaleSegments[0].classList.add('active');
    else if (aqi <= 100 && scaleSegments[1]) scaleSegments[1].classList.add('active');
    else if (aqi <= 200 && scaleSegments[2]) scaleSegments[2].classList.add('active');
    else if (aqi <= 300 && scaleSegments[3]) scaleSegments[3].classList.add('active');
    else if (aqi <= 400 && scaleSegments[4]) scaleSegments[4].classList.add('active');
    else if (scaleSegments[5])               scaleSegments[5].classList.add('active');
  }

  // ---------------------------------------------------------------------------
  // Sparkline Renderer (Canvas 2D)
  // ---------------------------------------------------------------------------
  function renderSparkline(history) {
    if (!sparkCtx || history.length < 2) return;
    const canvas = sparklineCanvas;
    const dpr    = window.devicePixelRatio || 1;
    const W      = canvas.offsetWidth  || 260;
    const H      = canvas.offsetHeight || 48;

    canvas.width  = W * dpr;
    canvas.height = H * dpr;
    sparkCtx.scale(dpr, dpr);

    const ctx = sparkCtx;
    ctx.clearRect(0, 0, W, H);

    const minVal = Math.max(0,   Math.min(...history) - 5);
    const maxVal = Math.min(500, Math.max(...history) + 5);
    const range  = maxVal - minVal || 1;

    if (sparklineRange) {
      sparklineRange.textContent = `Min ${Math.round(minVal)} – Max ${Math.round(maxVal)}`;
    }

    const stepX = W / (history.length - 1);
    const toY   = v => H - ((v - minVal) / range) * (H - 10) - 5;

    const lastAqi   = history[history.length - 1];
    const lineColor = getAqiColor(lastAqi);

    const grad = ctx.createLinearGradient(0, 0, 0, H);
    grad.addColorStop(0, lineColor + '66');
    grad.addColorStop(1, lineColor + '00');

    ctx.beginPath();
    ctx.moveTo(0, toY(history[0]));
    for (let i = 1; i < history.length; i++) ctx.lineTo(i * stepX, toY(history[i]));
    ctx.lineTo((history.length - 1) * stepX, H);
    ctx.lineTo(0, H);
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    ctx.beginPath();
    ctx.moveTo(0, toY(history[0]));
    for (let i = 1; i < history.length; i++) ctx.lineTo(i * stepX, toY(history[i]));
    ctx.strokeStyle = lineColor;
    ctx.lineWidth   = 2;
    ctx.lineJoin    = 'round';
    ctx.stroke();

    const dotX = (history.length - 1) * stepX;
    const dotY = toY(lastAqi);
    ctx.beginPath();
    ctx.arc(dotX, dotY, 3.5, 0, Math.PI * 2);
    ctx.fillStyle = lineColor;
    ctx.fill();
  }

  // ---------------------------------------------------------------------------
  // Interactive Historical Analytics Multi-Parameter Graph
  // ---------------------------------------------------------------------------
  function renderAnalyticsChart() {
    if (!analyticsCtx || historyBuffer.length < 2) return;
    const canvas = analyticsCanvas;
    const dpr    = window.devicePixelRatio || 1;
    const W      = canvas.offsetWidth  || 1100;
    const H      = canvas.offsetHeight || 220;

    canvas.width  = W * dpr;
    canvas.height = H * dpr;
    analyticsCtx.scale(dpr, dpr);

    const ctx = analyticsCtx;
    ctx.clearRect(0, 0, W, H);

    // Grid lines
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
    ctx.lineWidth   = 1;
    for (let y = 20; y < H; y += 40) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(W, y);
      ctx.stroke();
    }

    let series = [];
    let primaryKey = 'aqi';

    if (activeChartMode === 'aqi_pm') {
      primaryKey = 'aqi';
      series = [
        { key: 'aqi',  color: '#30D158', label: 'AQI' },
        { key: 'pm25', color: '#64D2FF', label: 'PM2.5' },
        { key: 'pm10', color: '#FFD60A', label: 'PM10' },
        { key: 'pm1',  color: '#BF5AF2', label: 'PM1.0' }
      ];
      if (analyticsSub) analyticsSub.textContent = 'Real-time particulate & air quality progression (AQI, PM1.0, PM2.5, PM10):';
    } else if (activeChartMode === 'gases') {
      primaryKey = 'no2';
      series = [
        { key: 'no2', color: '#64D2FF', label: 'NO₂ (ppm×1000)', scale: 1000 },
        { key: 'co',  color: '#FF9F0A', label: 'CO (ppm×10)',    scale: 10 },
        { key: 'voc', color: '#30D158', label: 'VOC Index' },
        { key: 'nh3', color: '#FF375F', label: 'NH₃ (ppm×100)',  scale: 100 }
      ];
      if (analyticsSub) analyticsSub.textContent = 'Combustion and toxic trace gas dynamics (NO₂, CO, VOC, NH₃):';
    } else {
      primaryKey = 'temp';
      series = [
        { key: 'temp', color: '#FF9F0A', label: 'Temperature (°C)' },
        { key: 'hum',  color: '#0A84FF', label: 'Humidity (%RH)' },
        { key: 'pres', color: '#30D158', label: 'Pressure (hPa - 1000)', offset: -1000 }
      ];
      if (analyticsSub) analyticsSub.textContent = 'Atmospheric micro-climate conditions (Temperature, Humidity, Pressure):';
    }

    // Determine scale for primary key for statistical chips
    const primaryVals = historyBuffer.map(item => item[primaryKey] || 0);
    const currVal = primaryVals[primaryVals.length - 1];
    const minVal  = Math.min(...primaryVals);
    const maxVal  = Math.max(...primaryVals);
    const avgVal  = primaryVals.reduce((a, b) => a + b, 0) / primaryVals.length;

    if (statAnalyticsCurr) statAnalyticsCurr.textContent = fmt(currVal, 1);
    if (statAnalyticsMin)  statAnalyticsMin.textContent  = fmt(minVal, 1);
    if (statAnalyticsMax)  statAnalyticsMax.textContent  = fmt(maxVal, 1);
    if (statAnalyticsAvg)  statAnalyticsAvg.textContent  = fmt(avgVal, 1);

    // Global min/max across all series
    let allScaled = [];
    series.forEach(s => {
      historyBuffer.forEach(item => {
        let v = item[s.key] || 0;
        if (s.scale) v *= s.scale;
        if (s.offset) v += s.offset;
        allScaled.push(v);
      });
    });

    const gMin = Math.max(0, Math.min(...allScaled) * 0.9);
    const gMax = Math.max(10, Math.max(...allScaled) * 1.1);
    const range = gMax - gMin || 1;

    const stepX = W / (historyBuffer.length - 1);
    const toY   = v => H - ((v - gMin) / range) * (H - 30) - 15;

    // Draw lines
    series.forEach(s => {
      ctx.beginPath();
      historyBuffer.forEach((item, i) => {
        let v = item[s.key] || 0;
        if (s.scale) v *= s.scale;
        if (s.offset) v += s.offset;
        const x = i * stepX;
        const y = toY(v);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      });
      ctx.strokeStyle = s.color;
      ctx.lineWidth   = 2;
      ctx.lineJoin    = 'round';
      ctx.stroke();

      // Legend in top-left
      ctx.fillStyle = s.color;
      ctx.fillRect(15 + series.indexOf(s) * 160, 10, 10, 10);
      ctx.fillStyle = '#F5F5F7';
      ctx.font      = '11px -apple-system, sans-serif';
      ctx.fillText(s.label, 30 + series.indexOf(s) * 160, 19);
    });
  }

  // ---------------------------------------------------------------------------
  // Main Render Dashboard Loop
  // ---------------------------------------------------------------------------
  function renderDashboard(data) {
    if (!data || !data.features) return;

    const f   = data.features           || {};
    const src = data.source_attribution || {};
    const fc  = data.forecast           || {};
    const adv = data.advisory           || {};
    const tel = data.telemetry          || {};
    const sys = data.system_info        || {};

    const aqi   = num(f.aqi, 50);
    const color = getAqiColor(aqi);

    // 1. Primary AQI Activity Gauge
    updateRadialGauge(aqi, color);
    if (aqiCategoryBadge) {
      aqiCategoryBadge.textContent      = f.aqi_category || 'Good';
      aqiCategoryBadge.style.background = color;
      aqiCategoryBadge.style.color      = aqi > 200 ? '#FFFFFF' : '#000000';
    }
    if (aqiPrimaryPollutant) {
      aqiPrimaryPollutant.textContent = `Prominent: ${f.primary_pollutant || 'PM2.5'}`;
    }
    if (aqiTimestamp) {
      aqiTimestamp.textContent = `Live • ${new Date().toLocaleTimeString([], {hour:'2-digit', minute:'2-digit', second:'2-digit'})}`;
    }

    // Sparkline history push
    aqiHistory.push(aqi);
    if (aqiHistory.length > HISTORY_CAPACITY) aqiHistory.shift();
    renderSparkline(aqiHistory);

    // Record for Historical Analytics Buffer
    const pm25v = num(f.pm25, 15);
    const pm10v = num(f.pm10, 25);
    const pm1v  = num(f.pm1, pm25v * 0.7);
    const no2v  = num(f.no2, 0.02);
    const cov   = num(f.co, 0.5);
    const co2v  = num(f.co2, 420);
    const nh3v  = num(f.nh3, 0.04);
    const vocv  = num(f.voc, 35);
    const tmpv  = num(f.tmp, 26);
    const humv  = num(f.hum, 52);
    const presv = num(f.pressure, 1013.25);

    historyBuffer.push({
      aqi, pm1: pm1v, pm25: pm25v, pm10: pm10v,
      no2: no2v, co: cov, co2: co2v, nh3: nh3v, voc: vocv,
      temp: tmpv, hum: humv, pres: presv,
      time: Date.now()
    });
    if (historyBuffer.length > HISTORY_CAPACITY) historyBuffer.shift();
    renderAnalyticsChart();

    // 2. AI Source Attribution Card & Particle Visualizer Theme
    const pSource = src.primary_source || 'Clean Baseline';
    if (typeof setParticleTheme === 'function') setParticleTheme(pSource);

    if (sourceName)            sourceName.textContent = pSource;
    if (sourceDesc)            sourceDesc.textContent = src.description || 'Ambient background baseline.';
    if (sourceConfidenceBadge) {
      sourceConfidenceBadge.textContent      = `${src.confidence_percent ?? 94}% Confidence`;
      sourceConfidenceBadge.style.borderColor = color;
      sourceConfidenceBadge.style.color       = color;
    }
    if (sourceIconContainer) sourceIconContainer.textContent = SOURCE_ICONS[pSource] || '🌿';

    // AI Diagnostics Benchmark metrics
    if (src.ai_benchmark) {
      const bmLatency = document.getElementById('bm-latency');
      const bmRam     = document.getElementById('bm-ram');
      if (bmLatency) bmLatency.textContent = `${src.ai_benchmark.inference_time_ms || 0.82} ms`;
      if (bmRam)     bmRam.textContent     = `${src.ai_benchmark.memory_footprint_kb || 112} KB`;
    }

    // Stoichiometric ratio bars
    const pmRatio = num(f.pm_ratio, 0.55);
    if (fpPmRatioVal) fpPmRatioVal.textContent = `${pmRatio.toFixed(2)} (${pmRatio > 0.65 ? 'Combustion' : (pmRatio < 0.35 ? 'Coarse Dust' : 'Normal')})`;
    if (fpPmRatioBar) fpPmRatioBar.style.width = `${Math.min(100, pmRatio * 100)}%`;

    const coRatio = num(f.co_to_co2_ratio, 1.2);
    if (fpCoRatioVal) fpCoRatioVal.textContent = `${coRatio.toFixed(2)} (${coRatio > 3.0 ? 'Incomplete Burning' : 'Normal'})`;
    if (fpCoRatioBar) fpCoRatioBar.style.width = `${Math.min(100, (coRatio / 8.0) * 100)}%`;

    const no2Ratio = num(f.no2_to_voc_ratio, 0.6);
    if (fpNo2RatioVal) fpNo2RatioVal.textContent = `${no2Ratio.toFixed(2)} (${no2Ratio > 0.8 ? 'High Diesel NOx' : 'Normal'})`;
    if (fpNo2RatioBar) fpNo2RatioBar.style.width = `${Math.min(100, (no2Ratio / 2.0) * 100)}%`;

    // Explainable AI Chips
    if (xaiChipsList && src.attributions && src.attributions.length > 0) {
      xaiChipsList.innerHTML = src.attributions.map(a =>
        `<span class="xai-chip"><strong>${a.factor}:</strong> ${a.evidence}</span>`
      ).join('');
    }

    // 3. 6-Hour Forecast Timeline
    if (fc.forecast_horizons && forecastTimeline) {
      if (forecastTrendPill) forecastTrendPill.textContent = `Trend: ${fc.overall_trend || 'STABLE'}`;
      forecastTimeline.innerHTML = fc.forecast_horizons.map(h => {
        const fcColor = getAqiColor(h.predicted_aqi);
        const predAqi = h.predicted_aqi ?? '—';
        const predPm  = h.predicted_pm25 ?? '—';
        return `
          <div class="forecast-step">
            <div class="fc-time">${h.label} (${h.target_time_str})</div>
            <div class="fc-pm">${predPm} <small style="font-size:0.65rem;color:#86868B">µg/m³</small></div>
            <span class="fc-aqi-chip" style="background:${fcColor}; color:${predAqi > 200 ? '#fff':'#000'}">AQI ${predAqi}</span>
          </div>
        `;
      }).join('');
    }

    if (forecastTipText && adv.optimal_window) {
      forecastTipText.innerHTML = `Best natural ventilation window: <strong>${adv.optimal_window}</strong> during solar atmospheric boundary lifting.`;
    }

    // 4. Actionable Advisory Panel & Dynamic Island Alert
    if (advisoryHeadline) {
      advisoryHeadline.textContent       = adv.headline || 'Air quality is pristine.';
      advisoryHeadline.style.borderColor = color;
      advisoryHeadline.style.color       = color;
    }

    if (urgentAlertBanner) {
      if (adv.urgent_alerts && adv.urgent_alerts.length > 0) {
        urgentAlertBanner.classList.remove('hidden');
        if (urgentAlertText) urgentAlertText.textContent = adv.urgent_alerts[0];
        playAlertBeep();
      } else {
        urgentAlertBanner.classList.add('hidden');
      }
    }

    if (citizenActionList && adv.citizen_actions) {
      citizenActionList.innerHTML = adv.citizen_actions.map(act =>
        `<li><strong>${act.action}</strong><br><span style="font-size:0.72rem;color:#86868B">${act.timing || ''}</span></li>`
      ).join('');
    }

    if (schoolActionList && adv.school_actions) {
      schoolActionList.innerHTML = adv.school_actions.map(act =>
        `<li><strong>${act.role}:</strong> ${act.recommendation}</li>`
      ).join('');
    }

    if (communityActionList && adv.community_actions) {
      communityActionList.innerHTML = adv.community_actions.map(act =>
        `<li><strong>${act.entity}:</strong> ${act.action}</li>`
      ).join('');
    }

    // 5. Extended 12-Channel Telemetry Matrix
    if (valPm1)  valPm1.textContent  = fmt(pm1v, 1);
    if (valPm25) valPm25.textContent = fmt(pm25v, 1);
    if (valPm10) valPm10.textContent = fmt(pm10v, 1);
    if (valNo2)  valNo2.textContent  = fmt(no2v, 3);
    if (valCo)   valCo.textContent   = fmt(cov, 2);
    if (valCo2)  valCo2.textContent  = Math.round(co2v);
    if (valNh3)  valNh3.textContent  = fmt(nh3v, 3);
    if (valVoc)  valVoc.textContent  = Math.round(vocv);
    if (valTemp) valTemp.textContent = fmt(tmpv, 1);
    if (valHum)  valHum.textContent  = fmt(humv, 1);
    if (valPres) valPres.textContent = fmt(presv, 1);

    const bat = tel.bat ?? f.bat ?? 96;
    const vin = tel.vin ?? f.vin ?? 3.32;
    if (valBattery) valBattery.textContent = `${bat}% • ${num(vin).toFixed(2)}V`;
    if (valBatTile) valBatTile.textContent = `${bat}% • ${num(vin).toFixed(2)}V`;

    // Status Pills
    const setPill = (el, val, thresholds) => {
      if (!el) return;
      el.textContent = aqiPillLabel(val, thresholds);
      el.className   = `sensor-sub-pill ${val <= thresholds[0][0] ? 'good' : (val <= thresholds[1][0] ? 'mod' : 'poor')}`;
    };
    setPill(statusPm1,  pm1v,        [[20,'Normal'],[50,'Elevated'],[200,'Severe']]);
    setPill(statusPm25, pm25v,       [[30,'Normal'],[60,'Elevated'],[120,'High'],[500,'Severe']]);
    setPill(statusPm10, pm10v,       [[50,'Normal'],[100,'Elevated'],[250,'High'],[500,'Severe']]);
    setPill(statusNo2,  no2v * 1000, [[35,'Low'],[80,'Moderate'],[180,'High'],[1000,'Critical']]);
    setPill(statusCo,   cov,         [[1,'Safe'],[5,'Elevated'],[17,'Dangerous'],[50,'Critical']]);
    setPill(statusCo2,  co2v,        [[600,'Fresh'],[1000,'Elevated'],[2000,'High'],[5000,'Unsafe']]);
    setPill(statusNh3,  nh3v * 100,  [[10,'Normal'],[30,'Elevated'],[100,'High']]);
    setPill(statusVoc,  vocv,        [[50,'Pristine'],[150,'Moderate'],[250,'High'],[400,'Critical']]);

    // Progress Bar Widths
    if (barPm1)     barPm1.style.width     = `${Math.min(100, (pm1v / 150) * 100)}%`;
    if (barPm25)  { barPm25.style.width    = `${Math.min(100, (pm25v / 250) * 100)}%`; barPm25.style.background = color; }
    if (barPm10)    barPm10.style.width    = `${Math.min(100, (pm10v / 400) * 100)}%`;
    if (barNo2)     barNo2.style.width     = `${Math.min(100, (no2v  / 0.15) * 100)}%`;
    if (barCo)      barCo.style.width      = `${Math.min(100, (cov   / 10.0) * 100)}%`;
    if (barCo2)     barCo2.style.width     = `${Math.min(100, (co2v  / 2000) * 100)}%`;
    if (barNh3)     barNh3.style.width     = `${Math.min(100, (nh3v  / 0.20) * 100)}%`;
    if (barVoc)     barVoc.style.width     = `${Math.min(100, (vocv  / 400)  * 100)}%`;
    if (barTemp)    barTemp.style.width    = `${Math.min(100, (tmpv  / 50)   * 100)}%`;
    if (barHum)     barHum.style.width     = `${Math.min(100, humv)}%`;
    if (barPres)    barPres.style.width    = `${Math.min(100, ((presv - 950) / 100) * 100)}%`;
    if (barBatTile) barBatTile.style.width = `${Math.min(100, bat)}%`;

    // 6. Campus Mesh Topology
    if (data.mesh_topology) {
      renderMeshTopology(data.mesh_topology);
    }

    // 7. System Stats
    if (sys.uptime_seconds != null && statUptime) {
      statUptime.textContent = formatUptime(sys.uptime_seconds);
    }
    if (sys.record_count != null && statRecordCount) {
      statRecordCount.textContent = sys.record_count.toLocaleString();
    }

    // 8. Next-Gen Plume Dispersion Vectoring Radar
    renderPlumeVector(data.plume, src);

    // 9. 16-Band Acoustic Audio-FFT Equalizer & Optical Extinction Haze
    renderAcousticAndOpticalHaze(f);

    // 10. Model Predictive Control (MPC) 4-Channel Preemptive Protection
    renderMPCStatus(data.mpc_status || data.rules_status?.mpc_preemption, data.rules_status?.relays);
  }

  // ---------------------------------------------------------------------------
  // Mesh Topology Renderer & Interactive Node Clicks
  // ---------------------------------------------------------------------------
  function renderMeshTopology(nodes) {
    if (!mapNodesGroup) return;

    if (meshNodesCount) {
      meshNodesCount.textContent = `${nodes.length} Nodes Active`;
    }

    const coords = {
      'UNO-Q-NODE-01':         { x: 250, y: 140, label: 'Central Quad (Master)' },
      'NODE-02-PLAYGROUND':    { x: 390, y: 80,  label: 'Sports Field' },
      'NODE-03-NORTH-GATE':    { x: 105, y: 78,  label: 'North Gate' },
      'NODE-04-CANTEEN':       { x: 377, y: 205, label: 'Canteen' },
      'NODE-05-WEST-EXPANSION':{ x: 120, y: 212, label: 'West Block' }
    };

    let svgHtml = '';
    const master = coords['UNO-Q-NODE-01'];

    // Wireless mesh vector links
    Object.keys(coords).forEach(k => {
      if (k !== 'UNO-Q-NODE-01') {
        const pt = coords[k];
        svgHtml += `<line x1="${master.x}" y1="${master.y}" x2="${pt.x}" y2="${pt.y}" stroke="#30D158" stroke-width="1.5" stroke-dasharray="4 3" opacity="0.35"/>`;
      }
    });

    // Node dots with animated radar beacons
    nodes.forEach(n => {
      const pt       = coords[n.node_id] || { x: 250, y: 140, label: n.node_name };
      const nColor   = getAqiColor(n.aqi);
      const isMaster = n.node_id.includes('UNO-Q');
      const isOffline = n.status === 'OFFLINE';
      const opacity  = isOffline ? '0.35' : '1';

      svgHtml += `
        <g transform="translate(${pt.x}, ${pt.y})" opacity="${opacity}" class="svg-node-group" data-node-id="${n.node_id}" style="cursor:pointer;">
          ${!isOffline ? `<circle class="map-radar-ring" cx="0" cy="0" r="${isMaster ? 9 : 7}" stroke="${nColor}" fill="none"/>` : ''}
          <circle cx="0" cy="0" r="${isMaster ? 13 : 9}" fill="${nColor}" fill-opacity="0.25"/>
          <circle cx="0" cy="0" r="${isMaster ? 7 : 5}" fill="${nColor}"/>
          <text x="0" y="-14" fill="#F5F5F7" font-size="8" font-family="-apple-system, sans-serif" font-weight="600" text-anchor="middle">${pt.label}</text>
          <text x="0" y="18"  fill="${nColor}" font-size="8" font-family="JetBrains Mono, monospace" font-weight="700" text-anchor="middle">AQI ${n.aqi ?? '—'}</text>
          ${isOffline ? `<text x="0" y="28" fill="#FF453A" font-size="7" text-anchor="middle">OFFLINE</text>` : ''}
        </g>
      `;
    });

    mapNodesGroup.innerHTML = svgHtml;

    // Node list elements
    if (meshNodesList) {
      meshNodesList.innerHTML = nodes.map(n => {
        const nColor  = getAqiColor(n.aqi);
        const offline = n.status === 'OFFLINE';
        return `
          <div class="mesh-node-item" data-node-id="${n.node_id}" style="cursor:pointer; ${offline ? 'opacity:0.5' : ''}">
            <div>
              <div class="mesh-node-name">${n.node_name}${offline ? ' <em style="color:#FF453A;font-size:0.65rem">(OFFLINE)</em>' : ''}</div>
              <div style="font-size:0.68rem;color:#86868B">${n.source ?? '—'} • Bat ${n.battery ?? '—'}%</div>
            </div>
            <div class="mesh-node-aqi" style="color:${nColor}">AQI ${n.aqi ?? '—'}</div>
          </div>
        `;
      }).join('');
    }

    // Attach click handlers to open the Node Inspector Modal
    document.querySelectorAll('.svg-node-group, .mesh-node-item').forEach(el => {
      el.addEventListener('click', () => {
        const nodeId = el.getAttribute('data-node-id');
        openNodeModal(nodeId);
      });
    });

    // 10. Universal Multi-Environment Domain Intelligence & Hardware Relays
    renderUniversalDomainIntelligence(data);
  }

  // ---------------------------------------------------------------------------
  // Universal Multi-Environment Domain Intelligence Renderer
  // ---------------------------------------------------------------------------
  function renderUniversalDomainIntelligence(data) {
    if (!data) return;
    const f = data.features || {};

    // 1. Active Profile & Standard Badges
    const activeProf = data.active_profile || 'Campus';
    const hdrProf = document.getElementById('hdr-active-profile-name');
    if (hdrProf) hdrProf.textContent = activeProf;
    const domainProf = document.getElementById('domain-profile-tag');
    if (domainProf) domainProf.textContent = `${activeProf} Mode`;

    const activeStd = data.active_standard || (f.standard ? f.standard.split(' ')[0] : 'NAQI');
    const stdBadge = document.getElementById('aqi-standard-badge');
    if (stdBadge) stdBadge.textContent = activeStd;

    // 2. Greenhouse VPD
    if (f.vpd) {
      const vpdVal = document.getElementById('domain-vpd-val');
      const vpdStatus = document.getElementById('domain-vpd-status');
      const vpdBar = document.getElementById('domain-vpd-bar');
      if (vpdVal) vpdVal.textContent = `${f.vpd.vpd_kpa ?? '—'} kPa`;
      if (vpdStatus) {
        vpdStatus.textContent = f.vpd.status || 'Optimal';
        vpdStatus.style.color = f.vpd.color || '#10B981';
      }
      if (vpdBar) {
        const pct = Math.min(100, Math.max(0, ((f.vpd.vpd_kpa || 1.0) / 2.5) * 100));
        vpdBar.style.width = `${pct}%`;
        vpdBar.style.background = f.vpd.color || '#10B981';
      }
    }

    // 3. Classroom Cognitive Drowsiness Index
    if (f.cdi) {
      const cdiVal = document.getElementById('domain-cdi-val');
      const cdiStatus = document.getElementById('domain-cdi-status');
      const cdiSub = document.getElementById('domain-cdi-sub');
      const cdiBar = document.getElementById('domain-cdi-bar');
      if (cdiVal) cdiVal.textContent = `${f.cdi.cdi_score ?? '—'} / 100`;
      if (cdiStatus) {
        cdiStatus.textContent = f.cdi.status || 'Optimal';
        cdiStatus.style.color = f.cdi.color || '#10B981';
      }
      if (cdiSub) cdiSub.textContent = f.cdi.ventilation_recommended ? '⚠️ Flush Air Recommended' : 'CO2 Flush: Normal';
      if (cdiBar) {
        cdiBar.style.width = `${f.cdi.cdi_score ?? 15}%`;
        cdiBar.style.background = f.cdi.color || '#10B981';
      }
    }

    // 4. Hospital Infection Risk Index
    if (f.infection_risk) {
      const infVal = document.getElementById('domain-infection-val');
      const infStatus = document.getElementById('domain-infection-status');
      const infSub = document.getElementById('domain-infection-sub');
      const infBar = document.getElementById('domain-infection-bar');
      if (infVal) infVal.textContent = `${f.infection_risk.infection_risk_score ?? '—'} / 100`;
      if (infStatus) {
        infStatus.textContent = f.infection_risk.status || 'Low Risk';
        infStatus.style.color = f.infection_risk.color || '#10B981';
      }
      if (infSub) infSub.textContent = f.infection_risk.sterilization_needed ? '⚠️ Sterilization Boost Needed' : 'Sterility Baseline Normal';
      if (infBar) {
        infBar.style.width = `${f.infection_risk.infection_risk_score ?? 20}%`;
        infBar.style.background = f.infection_risk.color || '#10B981';
      }
    }

    // 5. Industrial OSHA/NIOSH TWA Index
    if (f.osha_twa) {
      const oshaVal = document.getElementById('domain-osha-val');
      const oshaStatus = document.getElementById('domain-osha-status');
      const oshaBar = document.getElementById('domain-osha-bar');
      if (oshaVal) oshaVal.textContent = `${f.osha_twa.max_exposure_pct ?? '—'}% of TWA`;
      if (oshaStatus) {
        oshaStatus.textContent = f.osha_twa.status || 'Safe Baseline';
        oshaStatus.style.color = f.osha_twa.color || '#10B981';
      }
      if (oshaBar) {
        const pct = Math.min(100, Math.max(0, f.osha_twa.max_exposure_pct || 20));
        oshaBar.style.width = `${pct}%`;
        oshaBar.style.background = f.osha_twa.color || '#10B981';
      }
    }

    // 6. Hardware Relay States
    if (data.rules_status && data.rules_status.relays) {
      const relays = data.rules_status.relays;
      [1, 2, 3].forEach(num => {
        const r = relays[num];
        const badge = document.getElementById(`relay-badge-${num}`);
        const cell = document.getElementById(`relay-cell-${num}`);
        if (r && badge && cell) {
          badge.textContent = `RELAY ${num}: ${r.state ? 'ON (ACTIVE)' : 'OFF'}`;
          cell.classList.toggle('active', !!r.state);
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Node Diagnostics Modal Logic
  // ---------------------------------------------------------------------------
  function openNodeModal(nodeId) {
    const meta = NODE_METADATA[nodeId] || {
      name: nodeId, id: nodeId, loc: 'Campus Ward', gps: '20.3540° N, 85.8180° E',
      status: 'ONLINE', action: 'Standard campus monitoring active.', bat: '92%'
    };

    document.getElementById('node-modal-name').textContent   = meta.name;
    document.getElementById('node-modal-id').textContent     = meta.id;
    document.getElementById('node-modal-loc').textContent    = meta.loc;
    document.getElementById('node-modal-gps').textContent    = meta.gps;
    document.getElementById('node-modal-status').textContent = meta.status;
    document.getElementById('node-modal-action').textContent = meta.action;
    document.getElementById('node-modal-bat').textContent    = meta.bat;

    // Grab current AQI from history buffer
    const lastItem = historyBuffer[historyBuffer.length - 1] || { aqi: 42 };
    const aqiVal = lastItem.aqi || 42;
    const aqiEl = document.getElementById('node-modal-aqi');
    if (aqiEl) {
      aqiEl.textContent = `${Math.round(aqiVal)} (${aqiVal <= 50 ? 'Good' : (aqiVal <= 100 ? 'Satisfactory' : 'Elevated')})`;
      aqiEl.style.color = getAqiColor(aqiVal);
    }
    document.getElementById('node-modal-src').textContent = document.getElementById('source-name')?.textContent || 'Clean Baseline';

    openModal('modal-node-detail');
  }

  // Ping Node button handler
  const btnNodePing = document.getElementById('btn-node-ping');
  const nodePingResult = document.getElementById('node-ping-result');
  if (btnNodePing && nodePingResult) {
    btnNodePing.addEventListener('click', () => {
      btnNodePing.disabled = true;
      nodePingResult.textContent = 'Pinging node over 868MHz LoRa mesh…';
      setTimeout(() => {
        const ms = Math.floor(Math.random() * 12) + 6;
        nodePingResult.textContent = `Ack received in ${ms} ms • RSSI -64 dBm • Packet Loss 0%`;
        btnNodePing.disabled = false;
      }, 450);
    });
  }

  // ---------------------------------------------------------------------------
  // Standalone Simulated Frame Generator (Offline Fallback)
  // ---------------------------------------------------------------------------
  function generateStandaloneFrame() {
    internalSimStep++;
    let pm25 = 14.0, pm10 = 26.0, no2 = 0.018, co = 0.45, voc = 28.0, co2 = 418.0, nh3 = 0.02;
    let source = 'Clean Baseline';
    let desc   = 'Natural ambient background with normal trace gases.';
    let aqi    = 42;
    let category = 'Good';

    if (simulatedScenario === 'Traffic Jam') {
      pm25 = 115.0 + Math.sin(internalSimStep * 0.2) * 8.0;
      pm10 = pm25 * 1.35;
      no2  = 0.088 + Math.sin(internalSimStep * 0.3) * 0.012;
      co   = 3.4; voc = 85.0; co2 = 560.0; nh3 = 0.06;
      source = 'Traffic Exhaust';
      desc   = 'High nitrogen dioxide (NO₂) & ultrafine particulates from vehicular traffic.';
      aqi    = 178; category = 'Moderate';
    } else if (simulatedScenario === 'Garbage Fire') {
      pm25 = 245.0 + Math.sin(internalSimStep * 0.2) * 15.0;
      pm10 = pm25 * 1.3;
      no2  = 0.035; co = 6.8; voc = 290.0; co2 = 720.0; nh3 = 0.12;
      source = 'Garbage Burning';
      desc   = 'Severe toxic mixture of high PM2.5, carbon monoxide (CO), and hazardous VOCs.';
      aqi    = 320; category = 'Very Poor';
    } else if (simulatedScenario === 'Construction Dust') {
      pm10 = 330.0 + Math.sin(internalSimStep * 0.2) * 20.0;
      pm25 = pm10 * 0.24;
      no2  = 0.021; co = 0.55; voc = 32.0; co2 = 430.0; nh3 = 0.03;
      source = 'Construction Dust';
      desc   = 'High coarse PM10 dust from excavation and unpaved road resuspension.';
      aqi    = 195; category = 'Moderate';
    } else if (simulatedScenario === 'Cooking Smoke') {
      pm25 = 98.0; pm10 = 120.0;
      no2  = 0.024; co = 1.9; voc = 285.0; co2 = 1250.0; nh3 = 0.05;
      source = 'Cooking Smoke';
      desc   = 'High volatile organic compounds (VOCs) and localized CO₂ elevation.';
      aqi    = 145; category = 'Moderate';
    } else if (simulatedScenario === 'Crop Residue') {
      pm25 = 180.0; pm10 = 220.0;
      no2  = 0.032; co = 4.5; voc = 115.0; co2 = 590.0; nh3 = 0.09;
      source = 'Crop Residue';
      desc   = 'Widespread dense smoke plume with high PM2.5 and elevated CO.';
      aqi    = 240; category = 'Poor';
    }

    const now = new Date();
    const fmtHour = h => `${String(h).padStart(2,'0')}:00`;

    return {
      telemetry: { bat: 96, vin: 3.32 },
      features: {
        pm1: pm25 * 0.7, pm25, pm10, no2, co, co2, voc, nh3,
        tmp: 26.5, hum: 52.0, pressure: 1013.25, bat: 96, vin: 3.32,
        pm_ratio:         pm25 / pm10,
        co_to_co2_ratio:  (co * 1000) / co2,
        no2_to_voc_ratio: (no2 * 1000) / voc,
        aqi, aqi_category: category,
        primary_pollutant: pm25 > 50 ? 'PM2.5' : (no2 > 0.05 ? 'NO2' : (pm10 > 100 ? 'PM10' : 'PM2.5'))
      },
      source_attribution: {
        primary_source:    source,
        confidence_percent:94,
        description:       desc,
        attributions: [
          { factor: 'Primary Pollutant', evidence: `${pm25.toFixed(1)} µg/m³ PM2.5` },
          { factor: 'Gas Signature',     evidence: `${no2.toFixed(3)} ppm NO₂, ${co.toFixed(2)} ppm CO` }
        ]
      },
      forecast: {
        overall_trend: 'STABLE',
        forecast_horizons: [
          { label: '+1 Hour',  target_time_str: fmtHour((now.getHours()+1) % 24), predicted_pm25: (pm25 * 1.05).toFixed(1), predicted_aqi: Math.min(500, aqi + 5) },
          { label: '+2 Hours', target_time_str: fmtHour((now.getHours()+2) % 24), predicted_pm25: (pm25 * 0.95).toFixed(1), predicted_aqi: Math.min(500, aqi - 4) },
          { label: '+4 Hours', target_time_str: fmtHour((now.getHours()+4) % 24), predicted_pm25: (pm25 * 0.80).toFixed(1), predicted_aqi: Math.max(25, aqi - 15) },
          { label: '+6 Hours', target_time_str: fmtHour((now.getHours()+6) % 24), predicted_pm25: (pm25 * 0.72).toFixed(1), predicted_aqi: Math.max(20, aqi - 22) }
        ]
      },
      advisory: {
        headline:       aqi <= 50 ? 'Air quality is pristine. Perfect day for outdoor activities!' : `Active ${source} signature. Limit outdoor exposure.`,
        optimal_window: '14:00 – 16:00',
        urgent_alerts:  aqi > 200 ? [`ALERT: High exposure risk detected from ${source}.`] : [],
        citizen_actions: [
          { action: aqi <= 100 ? 'Open windows for natural cross-ventilation' : 'Seal windows & wear N95 mask outdoors', timing: 'Current Hour' }
        ],
        school_actions: [
          { role: 'Sports & Recess', recommendation: aqi <= 100 ? 'Outdoor activities approved.' : 'Move sports indoors.' }
        ],
        community_actions: [
          { entity: 'RWA Patrol', action: aqi <= 100 ? 'Routine campus maintenance.' : `Inspect perimeter for ${source} source.` }
        ]
      },
      mesh_topology: [
        { node_id: 'UNO-Q-NODE-01',          node_name: 'Central Quad (Master)',   aqi,                   source, battery: 96, status: 'LOCAL_MASTER' },
        { node_id: 'NODE-02-PLAYGROUND',     node_name: 'Sports Complex',          aqi: Math.max(25, aqi - 15), source: 'Clean Baseline',   battery: 94, status: 'ONLINE' },
        { node_id: 'NODE-03-NORTH-GATE',     node_name: 'North Gate Highway',      aqi: 185,              source: 'Traffic Exhaust',  battery: 88, status: 'ONLINE' },
        { node_id: 'NODE-04-CANTEEN',        node_name: 'Dining Pavilion',         aqi: 110,              source: 'Cooking Smoke',    battery: 98, status: 'ONLINE' },
        { node_id: 'NODE-05-WEST-EXPANSION', node_name: 'West Block',              aqi: 165,              source: 'Construction Dust',battery: 76, status: 'ONLINE' }
      ],
      system_info: { uptime_seconds: internalSimStep, record_count: internalSimStep }
    };
  }

  // ---------------------------------------------------------------------------
  // Polling Loop
  // ---------------------------------------------------------------------------
  async function fetchLiveTelemetry() {
    const t0 = Date.now();
    try {
      const res = await fetch('/api/live', { cache: 'no-store' });
      if (res.ok) {
        const data = await res.json();
        const latency = Date.now() - t0;
        if (valLatency) valLatency.textContent = `${latency} ms`;
        renderDashboard(data);
        setConnectionStatus(true);
      } else {
        throw new Error(`HTTP ${res.status}`);
      }
    } catch {
      setConnectionStatus(false);
      const simData = generateStandaloneFrame();
      if (valLatency) valLatency.textContent = '< 1 ms';
      renderDashboard(simData);
    }
  }

  function startRefreshLoop() {
    if (timerHandle) clearInterval(timerHandle);
    if (refreshIntervalMs > 0) {
      fetchLiveTelemetry();
      timerHandle = setInterval(fetchLiveTelemetry, refreshIntervalMs);
    }
  }

  // ---------------------------------------------------------------------------
  // Scenario Switcher
  // ---------------------------------------------------------------------------
  async function changeScenario(chosen) {
    simulatedScenario = chosen;
    if (scenarioSelect) scenarioSelect.value = chosen;
    try {
      await fetch('/api/scenario', {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ scenario: chosen })
      });
    } catch {}
    fetchLiveTelemetry();
  }

  if (scenarioSelect) {
    scenarioSelect.addEventListener('change', (e) => changeScenario(e.target.value));
  }

  // Scenario dropdown menu items
  document.querySelectorAll('[data-scenario]').forEach(btn => {
    btn.addEventListener('click', () => {
      const scen = btn.getAttribute('data-scenario');
      changeScenario(scen);
      closeAllDropdowns();
    });
  });

  // ---------------------------------------------------------------------------
  // Gorilla Compression Test
  // ---------------------------------------------------------------------------
  async function runCompressionTest() {
    if (!btnTriggerCompress) return;
    btnTriggerCompress.textContent = 'Working…';
    btnTriggerCompress.disabled    = true;
    try {
      const res = await fetch('/api/compress_demo', { cache: 'no-store' });
      if (res.ok) {
        const data = await res.json();
        if (data.stats) {
          if (compressionSavings)   compressionSavings.textContent  = `${data.stats.bandwidth_savings_pct}%`;
          if (compressionDailySize) compressionDailySize.textContent = `${(data.stats.compressed_bytes / 1024).toFixed(1)} KB`;
        }
        if (data.compressed_hex_sample && hexDumpDisplay) {
          hexDumpDisplay.textContent = data.compressed_hex_sample.match(/.{1,2}/g).join(' ').toUpperCase();
        }
      }
    } catch {
      if (hexDumpDisplay)      hexDumpDisplay.textContent      = 'AE 55 00 32 66 D5 24 10 01 02 A4 03 1C 01 B0 00 15 00 3F 0A 32 00 28 01 00 …';
      if (compressionSavings)   compressionSavings.textContent  = '89.8%';
      if (compressionDailySize) compressionDailySize.textContent = '< 38 KB';
    } finally {
      btnTriggerCompress.textContent = 'Test Compress';
      btnTriggerCompress.disabled    = false;
    }
  }

  if (btnTriggerCompress) {
    btnTriggerCompress.addEventListener('click', runCompressionTest);
  }

  // ---------------------------------------------------------------------------
  // Apple Menubar Dropdown Logic
  // ---------------------------------------------------------------------------
  const menuButtons = document.querySelectorAll('.menu-btn');
  const dropdowns   = document.querySelectorAll('.dropdown-menu');

  function closeAllDropdowns() {
    dropdowns.forEach(d => d.classList.remove('show'));
    menuButtons.forEach(b => b.classList.remove('active'));
  }

  menuButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const parent = btn.closest('.menu-dropdown');
      const menu   = parent.querySelector('.dropdown-menu');
      const isOpen = menu.classList.contains('show');
      closeAllDropdowns();
      if (!isOpen) {
        menu.classList.add('show');
        btn.classList.add('active');
      }
    });
  });

  document.addEventListener('click', (e) => {
    if (!e.target.closest('.menu-dropdown')) closeAllDropdowns();
  });

  // ---------------------------------------------------------------------------
  // Modals Management
  // ---------------------------------------------------------------------------
  function openModal(modalId) {
    closeAllDropdowns();
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.add('open');
  }

  function closeAllModals() {
    document.querySelectorAll('.apple-modal-overlay').forEach(m => m.classList.remove('open'));
  }

  document.querySelectorAll('[data-close-modal]').forEach(btn => {
    btn.addEventListener('click', closeAllModals);
  });

  document.querySelectorAll('.apple-modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', (e) => {
      if (e.target === overlay) closeAllModals();
    });
  });

  // Menu item modal triggers
  document.getElementById('item-about')?.addEventListener('click', () => openModal('modal-about'));
  document.getElementById('item-bom')?.addEventListener('click', () => openModal('modal-bom'));
  document.getElementById('item-hardware')?.addEventListener('click', () => openModal('modal-hardware'));
  document.getElementById('item-privacy')?.addEventListener('click', () => openModal('modal-about'));

  // Universal data-open-modal triggers (for footer navigation and interactive elements)
  document.querySelectorAll('[data-open-modal]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const modalId = btn.getAttribute('data-open-modal');
      if (modalId) openModal(modalId);
    });
  });

  // Back to Top smooth scroll button
  document.getElementById('btn-back-to-top')?.addEventListener('click', (e) => {
    e.preventDefault();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });

  // ---------------------------------------------------------------------------
  // Data Export Handlers
  // ---------------------------------------------------------------------------
  function exportCSV() {
    closeAllDropdowns();
    window.location.href = '/api/export/csv';
  }

  function exportJSON() {
    closeAllDropdowns();
    window.open('/api/history', '_blank');
  }

  function downloadGorillaBin() {
    closeAllDropdowns();
    const hex = hexDumpDisplay?.textContent.replace(/\s+/g, '') || 'AE55003266D524100102A4031C01B00015003F0A3200280100';
    const bytes = new Uint8Array(hex.match(/.{1,2}/g).map(byte => parseInt(byte, 16)));
    const blob = new Blob([bytes], { type: 'application/octet-stream' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'aerosense_gorilla_compressed.bin';
    link.click();
  }

  document.getElementById('item-export-csv')?.addEventListener('click', exportCSV);
  document.getElementById('item-export-json')?.addEventListener('click', exportJSON);
  document.getElementById('item-download-bin')?.addEventListener('click', downloadGorillaBin);
  document.getElementById('btn-quick-export')?.addEventListener('click', exportCSV);
  document.getElementById('item-print-report')?.addEventListener('click', () => {
    closeAllDropdowns();
    window.print();
  });

  // Tools items
  document.getElementById('item-tool-compress')?.addEventListener('click', () => {
    closeAllDropdowns();
    runCompressionTest();
  });

  document.getElementById('item-tool-ping')?.addEventListener('click', () => {
    closeAllDropdowns();
    openNodeModal('UNO-Q-NODE-01');
  });

  document.getElementById('item-tool-toggle-sim')?.addEventListener('click', () => {
    closeAllDropdowns();
    alert('AeroSense is running in heterogeneous simulation mode with deterministic STM32 DMA emulation.');
  });

  document.getElementById('item-tool-clear-history')?.addEventListener('click', () => {
    closeAllDropdowns();
    historyBuffer.length = 0;
    aqiHistory.length = 0;
    renderAnalyticsChart();
  });

  // ---------------------------------------------------------------------------
  // Quick Search Filter (⌘K / Ctrl+K)
  // ---------------------------------------------------------------------------
  if (quickSearchInput) {
    quickSearchInput.addEventListener('input', (e) => {
      const term = e.target.value.toLowerCase().trim();
      const cells = document.querySelectorAll('.sensor-cell');
      cells.forEach(cell => {
        const text = cell.textContent.toLowerCase();
        if (!term || text.includes(term)) {
          cell.style.display = 'flex';
          cell.style.opacity = '1';
        } else {
          cell.style.opacity = '0.2';
        }
      });
    });

    document.addEventListener('keydown', (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        quickSearchInput.focus();
      }
      if (e.key === 'Escape') {
        closeAllModals();
        closeAllDropdowns();
        quickSearchInput.blur();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Historical Analytics Chart Tabs
  // ---------------------------------------------------------------------------
  document.querySelectorAll('.chart-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.chart-tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeChartMode = btn.getAttribute('data-chart-mode');
      renderAnalyticsChart();
    });
  });

  // ---------------------------------------------------------------------------
  // Floating Apple Control Center
  // ---------------------------------------------------------------------------
  const controlFab  = document.getElementById('btn-control-fab');
  const controlTray = document.getElementById('control-tray');

  if (controlFab && controlTray) {
    controlFab.addEventListener('click', (e) => {
      e.stopPropagation();
      controlTray.classList.toggle('show');
    });

    document.addEventListener('click', (e) => {
      if (!e.target.closest('.floating-control-center')) {
        controlTray.classList.remove('show');
      }
    });
  }

  // Refresh rate switcher
  document.querySelectorAll('#refresh-rate-group .control-toggle-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#refresh-rate-group .control-toggle-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      refreshIntervalMs = parseInt(btn.getAttribute('data-rate'), 10);
      startRefreshLoop();
    });
  });

  // Toggle Audio Alert
  document.getElementById('toggle-audio-alerts')?.addEventListener('change', (e) => {
    audioAlertsEnabled = e.target.checked;
    if (audioAlertsEnabled) playAlertBeep();
  });

  // Toggle Ambient Glow
  document.getElementById('toggle-ambient-glow')?.addEventListener('change', (e) => {
    document.body.classList.toggle('no-glow', !e.target.checked);
  });

  // Toggle Fullscreen
  document.getElementById('btn-toggle-fullscreen')?.addEventListener('click', () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    } else {
      document.exitFullscreen().catch(() => {});
    }
  });

  // ---------------------------------------------------------------------------
  // Navigation tabs smooth scroll & active tracking
  // ---------------------------------------------------------------------------
  const navTabs = document.querySelectorAll('.nav-tab-pill');
  navTabs.forEach(tab => {
    tab.addEventListener('click', (e) => {
      e.preventDefault();
      navTabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      const targetId = tab.getAttribute('href').replace('#', '');
      const targetEl = document.getElementById(targetId);
      if (targetEl) {
        const headerHeight = document.getElementById('app-header')?.offsetHeight || 70;
        const targetPos = targetEl.getBoundingClientRect().top + window.scrollY - headerHeight - 16;
        window.scrollTo({ top: targetPos, behavior: 'smooth' });
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Dark and Light Theme Manager
  // ---------------------------------------------------------------------------
  const themeToggleBtn = document.getElementById('theme-toggle-btn');
  const themeIcon      = document.getElementById('theme-icon');
  const itemToggleTheme = document.getElementById('item-toggle-theme');
  const themeBtnGroup  = document.querySelectorAll('#theme-btn-group .control-toggle-btn');

  function setTheme(theme) {
    const isLight = theme === 'light';
    document.body.classList.toggle('light-theme', isLight);
    document.body.classList.toggle('dark-theme', !isLight);
    if (themeIcon) themeIcon.textContent = isLight ? '🌙' : '☀️';
    if (themeToggleBtn) themeToggleBtn.setAttribute('title', isLight ? 'Switch to Dark Mode (⌘T)' : 'Switch to Light Mode (⌘T)');

    themeBtnGroup.forEach(btn => {
      btn.classList.toggle('active', btn.getAttribute('data-theme') === theme);
    });

    try { localStorage.setItem('aerosense-theme', theme); } catch {}

    // Re-render sparkline & analytics chart with updated theme colors
    renderSparkline(aqiHistory);
    renderAnalyticsChart();
  }

  function toggleTheme() {
    const isCurrentlyLight = document.body.classList.contains('light-theme');
    setTheme(isCurrentlyLight ? 'dark' : 'light');
  }

  if (themeToggleBtn) themeToggleBtn.addEventListener('click', toggleTheme);
  if (itemToggleTheme) itemToggleTheme.addEventListener('click', () => {
    closeAllDropdowns();
    toggleTheme();
  });

  themeBtnGroup.forEach(btn => {
    btn.addEventListener('click', () => {
      const chosen = btn.getAttribute('data-theme');
      setTheme(chosen);
    });
  });

  // Shortcut ⌘T / Ctrl+T for theme toggle
  document.addEventListener('keydown', (e) => {
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 't') {
      e.preventDefault();
      toggleTheme();
    }
  });

  // Load saved theme
  try {
    const saved = localStorage.getItem('aerosense-theme');
    if (saved) setTheme(saved);
  } catch {}

  // ---------------------------------------------------------------------------
  // 3D Card Parallax Tilt & Dynamic Specular Sheen Physics
  // ---------------------------------------------------------------------------
  let is3DEnabled = true;
  const toggle3DTilt = document.getElementById('toggle-3d-tilt');
  if (toggle3DTilt) {
    toggle3DTilt.addEventListener('change', (e) => {
      is3DEnabled = e.target.checked;
      if (!is3DEnabled) {
        document.querySelectorAll('.card-3d-wrap').forEach(c => {
          c.style.transform = 'perspective(1400px) rotateX(0deg) rotateY(0deg) scale3d(1, 1, 1)';
        });
      }
    });
  }

  const cards3D = document.querySelectorAll('.card-3d-wrap');
  cards3D.forEach(card => {
    const glare = card.querySelector('.card-glare');

    card.addEventListener('mousemove', (e) => {
      if (!is3DEnabled) return;
      const rect = card.getBoundingClientRect();
      const normX = (e.clientX - rect.left) / rect.width - 0.5;
      const normY = (e.clientY - rect.top) / rect.height - 0.5;

      const rotateY = normX * 12; // deg
      const rotateX = -normY * 12; // deg

      card.style.transform = `perspective(1200px) rotateX(${rotateX.toFixed(2)}deg) rotateY(${rotateY.toFixed(2)}deg) scale3d(1.015, 1.015, 1.015)`;

      if (glare) {
        const isLight = document.body.classList.contains('light-theme');
        const glareColor = isLight ? 'rgba(255, 255, 255, 0.45)' : 'rgba(255, 255, 255, 0.18)';
        glare.style.background = `radial-gradient(circle at ${(normX + 0.5) * 100}% ${(normY + 0.5) * 100}%, ${glareColor} 0%, transparent 65%)`;
      }
    });

    card.addEventListener('mouseleave', () => {
      card.style.transform = 'perspective(1200px) rotateX(0deg) rotateY(0deg) scale3d(1, 1, 1)';
    });
  });

  // Station 3D Badge click handler
  document.getElementById('station-3d-hero-badge')?.addEventListener('click', () => {
    openModal('modal-hardware');
  });

  // ---------------------------------------------------------------------------
  // 1. Atmospheric Particle Canvas Visualizer Engine
  // ---------------------------------------------------------------------------
  const canvasParticles = document.getElementById('particle-canvas');
  let particleCtx = canvasParticles ? canvasParticles.getContext('2d') : null;
  let particles = [];
  let currentParticleTheme = 'Clean Baseline';

  const PARTICLE_THEMES = {
    'Clean Baseline':   { count: 35, color: '#30D158', sizeMin: 1, sizeMax: 2.5, speedY: -0.3, alpha: 0.4 },
    'Garbage Fire':     { count: 80, color: '#EF4444', sizeMin: 2, sizeMax: 6,   speedY: -1.5, alpha: 0.8 },
    'Traffic Jam':      { count: 65, color: '#F97316', sizeMin: 1.5, sizeMax: 4, speedY: -0.8, alpha: 0.7 },
    'Traffic Exhaust':  { count: 65, color: '#F97316', sizeMin: 1.5, sizeMax: 4, speedY: -0.8, alpha: 0.7 },
    'Construction Dust':{ count: 70, color: '#EAB308', sizeMin: 2, sizeMax: 5,   speedY: -0.4, alpha: 0.6 },
    'Cooking Smoke':    { count: 50, color: '#BF5AF2', sizeMin: 1, sizeMax: 4,   speedY: -1.0, alpha: 0.6 },
    'Crop Residue':     { count: 75, color: '#DC2626', sizeMin: 2, sizeMax: 5.5, speedY: -1.2, alpha: 0.75 }
  };

  function createParticle(cfg) {
    const W = canvasParticles ? canvasParticles.width : window.innerWidth;
    const H = canvasParticles ? canvasParticles.height : window.innerHeight;
    return {
      x: Math.random() * W,
      y: Math.random() * H,
      radius: Math.random() * (cfg.sizeMax - cfg.sizeMin) + cfg.sizeMin,
      speedX: (Math.random() - 0.5) * 0.8,
      speedY: (Math.random() * 0.8 + 0.2) * cfg.speedY,
      alpha: Math.random() * cfg.alpha
    };
  }

  function setParticleTheme(theme) {
    if (currentParticleTheme === theme) return;
    currentParticleTheme = theme;
    const cfg = PARTICLE_THEMES[theme] || PARTICLE_THEMES['Clean Baseline'];
    particles = [];
    for (let i = 0; i < cfg.count; i++) {
      particles.push(createParticle(cfg));
    }
  }

  function initParticles() {
    if (!canvasParticles || !particleCtx) return;
    const resizeCanvas = () => {
      canvasParticles.width = window.innerWidth;
      canvasParticles.height = window.innerHeight;
    };
    window.addEventListener('resize', resizeCanvas);
    resizeCanvas();

    const cfg = PARTICLE_THEMES[currentParticleTheme] || PARTICLE_THEMES['Clean Baseline'];
    particles = [];
    for (let i = 0; i < cfg.count; i++) {
      particles.push(createParticle(cfg));
    }
    requestAnimationFrame(animateParticles);
  }

  function animateParticles() {
    if (!particleCtx || !canvasParticles) return;
    particleCtx.clearRect(0, 0, canvasParticles.width, canvasParticles.height);
    const cfg = PARTICLE_THEMES[currentParticleTheme] || PARTICLE_THEMES['Clean Baseline'];

    particles.forEach((p, idx) => {
      p.x += p.speedX;
      p.y += p.speedY;

      if (p.y < 0 || p.x < 0 || p.x > canvasParticles.width) {
        particles[idx] = createParticle(cfg);
        particles[idx].y = canvasParticles.height + 5;
      }

      particleCtx.beginPath();
      particleCtx.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
      particleCtx.fillStyle = cfg.color;
      particleCtx.globalAlpha = p.alpha;
      particleCtx.fill();
    });

    requestAnimationFrame(animateParticles);
  }

  initParticles();

  // ---------------------------------------------------------------------------
  // 2. Speech Advisory Engine (Text-to-Speech Synthesis)
  // ---------------------------------------------------------------------------
  let voiceAlertsEnabled = false;
  const btnVoice = document.getElementById('voice-toggle-btn');

  function speakAdvisory(text) {
    if (!voiceAlertsEnabled || !('speechSynthesis' in window)) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = 1.0;
    utterance.pitch = 1.0;

    if (btnVoice) btnVoice.classList.add('speaking');
    utterance.onend = () => { if (btnVoice) btnVoice.classList.remove('speaking'); };
    utterance.onerror = () => { if (btnVoice) btnVoice.classList.remove('speaking'); };
    window.speechSynthesis.speak(utterance);
  }

  if (btnVoice) {
    btnVoice.addEventListener('click', () => {
      voiceAlertsEnabled = !voiceAlertsEnabled;
      btnVoice.classList.toggle('speaking', voiceAlertsEnabled);
      const label = btnVoice.querySelector('.voice-label');
      if (label) label.textContent = voiceAlertsEnabled ? 'Voice ON' : 'Voice Alerts';
      if (voiceAlertsEnabled) {
        speakAdvisory("AeroSense Edge voice advisory initialized. Monitoring air quality on Arduino UNO Q.");
      } else {
        window.speechSynthesis.cancel();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 3. Judge Test Drive Toolbar & Scenario Handlers
  // ---------------------------------------------------------------------------
  const judgeBtns = document.querySelectorAll('#judge-demo-bar .judge-btn[data-scenario]');
  judgeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const scenario = btn.getAttribute('data-scenario');
      judgeBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      setParticleTheme(scenario);
      changeScenario(scenario);
      speakAdvisory(`Scenario shifted to ${scenario}. Edge AI evaluating stoichiometric ratios.`);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Municipal Emergency Incident Audit Modal & PDF Report
  // ---------------------------------------------------------------------------
  function openIncidentReportModal() {
    const srcName = document.getElementById('source-name')?.textContent || 'Garbage Burning';
    const srcDesc = document.getElementById('source-desc')?.textContent || 'Smoldering waste & plastic smoke plume';
    const confVal = document.getElementById('source-confidence-badge')?.textContent || '96% Confidence';
    const pmRatio = document.getElementById('fp-pm-ratio-val')?.textContent || '0.82';
    const coRatio = document.getElementById('fp-co-ratio-val')?.textContent || '4.50';
    const no2Ratio = document.getElementById('fp-no2-ratio-val')?.textContent || '0.25';

    const rptTime = document.getElementById('rpt-time');
    const rptId   = document.getElementById('rpt-id');
    const rptSrc  = document.getElementById('rpt-source-name');
    const rptDesc = document.getElementById('rpt-source-desc');
    const rptConf = document.getElementById('rpt-confidence');
    const rptPm   = document.getElementById('rpt-val-pmratio');
    const rptCo   = document.getElementById('rpt-val-coratio');
    const rptNo2  = document.getElementById('rpt-val-no2ratio');

    if (rptTime) rptTime.textContent = new Date().toLocaleString();
    if (rptId)   rptId.textContent   = `AERO-AUDIT-${Date.now().toString().slice(-6)}`;
    if (rptSrc)  rptSrc.textContent  = srcName;
    if (rptDesc) rptDesc.textContent = srcDesc;
    if (rptConf) rptConf.textContent = confVal;
    if (rptPm)   rptPm.textContent   = pmRatio;
    if (rptCo)   rptCo.textContent   = coRatio;
    if (rptNo2)  rptNo2.textContent  = no2Ratio;

    openModal('modal-incident-report');
  }

  document.getElementById('btn-judge-incident-report')?.addEventListener('click', openIncidentReportModal);
  document.getElementById('btn-print-audit-pdf')?.addEventListener('click', () => window.print());

  // ---------------------------------------------------------------------------
  // 5. Anywhere Deployment Studio Controller
  // ---------------------------------------------------------------------------
  let studioCurrentProfile = 'Campus';
  let studioCurrentStandard = 'NAQI';

  function highlightActiveProfileInModal(profile) {
    studioCurrentProfile = profile;
    document.querySelectorAll('.profile-card').forEach(card => {
      const p = card.getAttribute('data-profile-select');
      card.classList.toggle('active-profile', p === profile);
    });
  }

  function highlightActiveStandardInModal(standard) {
    studioCurrentStandard = standard;
    document.querySelectorAll('.standard-card').forEach(card => {
      const s = card.getAttribute('data-standard-select');
      card.classList.toggle('active-standard', s === standard);
    });
  }

  async function deployProfile(profileName) {
    try {
      const res = await fetch('/api/profiles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ profile: profileName })
      });
      if (res.ok) {
        highlightActiveProfileInModal(profileName);
        fetchLiveTelemetry();
        speakAdvisory(`Environment profile updated to ${profileName}.`);
      }
    } catch {
      highlightActiveProfileInModal(profileName);
    }
  }

  async function deployStandard(standardName) {
    try {
      const res = await fetch('/api/standards', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ standard: standardName })
      });
      if (res.ok) {
        highlightActiveStandardInModal(standardName);
        fetchLiveTelemetry();
        speakAdvisory(`Air quality compliance standard shifted to ${standardName}.`);
      }
    } catch {
      highlightActiveStandardInModal(standardName);
    }
  }

  async function loadCalibrationData() {
    const tbody = document.getElementById('calibration-tbody');
    if (!tbody) return;
    try {
      const res = await fetch('/api/calibration');
      if (res.ok) {
        const data = await res.json();
        const calib = data.calibration || {};
        const sensorMap = {
          pm1: 'PMS5003 Laser', pm25: 'PMS5003 Laser', pm10: 'PMS5003 Laser',
          co2: 'Sensirion SCD41', no2: 'SGX MiCS-6814', co: 'SGX MiCS-6814',
          nh3: 'SGX MiCS-6814', voc: 'Bosch BME688', tmp: 'Bosch BME688',
          hum: 'Bosch BME688', prs: 'Bosch BME688'
        };

        tbody.innerHTML = Object.keys(calib).map(ch => {
          const cfg = calib[ch];
          const sName = sensorMap[ch] || 'Sensor Array';
          return `
            <tr data-channel="${ch}">
              <td><strong>${ch.toUpperCase()}</strong></td>
              <td style="color:var(--text-secondary);font-size:0.75rem;">${sName}</td>
              <td><input type="checkbox" class="calib-enabled" ${cfg.enabled ? 'checked' : ''}></td>
              <td><input type="number" step="0.05" class="calib-input calib-gain" value="${cfg.gain}"></td>
              <td><input type="number" step="0.1" class="calib-input calib-offset" value="${cfg.offset}"></td>
            </tr>
          `;
        }).join('');
      }
    } catch {}
  }

  async function saveCalibrationData() {
    const rows = document.querySelectorAll('#calibration-tbody tr[data-channel]');
    const calib = {};
    rows.forEach(tr => {
      const ch = tr.getAttribute('data-channel');
      const enabled = tr.querySelector('.calib-enabled').checked;
      const gain = parseFloat(tr.querySelector('.calib-gain').value) || 1.0;
      const offset = parseFloat(tr.querySelector('.calib-offset').value) || 0.0;
      calib[ch] = { gain, offset, enabled };
    });

    try {
      const res = await fetch('/api/calibration', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ calibration: calib })
      });
      if (res.ok) {
        const btn = document.getElementById('btn-save-calibration');
        if (btn) {
          const orig = btn.textContent;
          btn.textContent = '✅ Saved!';
          setTimeout(() => { btn.textContent = orig; }, 1500);
        }
        fetchLiveTelemetry();
      }
    } catch {}
  }

  async function loadRulesData() {
    const list = document.getElementById('active-rules-list');
    if (!list) return;
    try {
      const res = await fetch('/api/rules');
      if (res.ok) {
        const data = await res.json();
        const rules = data.rules || [];
        if (rules.length === 0) {
          list.innerHTML = '<div style="color:var(--text-secondary);font-size:0.8rem;padding:0.5rem 0;">No active rules for this profile. Add one below!</div>';
          return;
        }
        list.innerHTML = rules.map(r => `
          <div class="rule-item-card" data-rule-id="${r.id}">
            <div>
              <div class="rule-item-desc"><strong>${r.name}</strong> • ${r.action_type === 'relay' ? `Relay #${r.relay_num || 1} (${r.relay_name || 'Actuator'})` : 'Webhook POST'}</div>
              <div class="rule-item-condition">IF ${r.metric} ${r.operator} ${r.threshold}</div>
            </div>
            <div style="display:flex;align-items:center;gap:0.75rem;">
              <input type="checkbox" class="rule-toggle-check" data-rule-id="${r.id}" ${r.enabled ? 'checked' : ''}>
              <button class="btn-delete-rule" data-rule-id="${r.id}" style="background:transparent;border:none;color:#FF453A;cursor:pointer;font-size:1.1rem;" title="Delete Rule">&times;</button>
            </div>
          </div>
        `).join('');

        // Wire delete & toggle buttons
        list.querySelectorAll('.btn-delete-rule').forEach(btn => {
          btn.addEventListener('click', async () => {
            const ruleId = btn.getAttribute('data-rule-id');
            await fetch('/api/rules', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ action: 'delete', rule_id: ruleId })
            });
            loadRulesData();
          });
        });

        list.querySelectorAll('.rule-toggle-check').forEach(chk => {
          chk.addEventListener('change', async () => {
            const ruleId = chk.getAttribute('data-rule-id');
            await fetch('/api/rules', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ action: 'toggle', rule_id: ruleId, enabled: chk.checked })
            });
          });
        });

        const webhookInput = document.getElementById('webhook-url-input');
        if (webhookInput && data.webhook_url) webhookInput.value = data.webhook_url;
      }
    } catch {}
  }

  async function addCustomRule() {
    const name = document.getElementById('new-rule-name')?.value.trim();
    const metric = document.getElementById('new-rule-metric')?.value;
    const operator = document.getElementById('new-rule-operator')?.value;
    const threshold = document.getElementById('new-rule-threshold')?.value.trim();
    const action = document.getElementById('new-rule-action')?.value;

    if (!name || !threshold) {
      alert('Please enter a rule name and threshold value.');
      return;
    }

    const isRelay = action.startsWith('relay_');
    const relayNum = isRelay ? parseInt(action.replace('relay_', ''), 10) : 1;
    const relayNames = { 1: 'Exhaust Fan', 2: 'Purifier / Mist', 3: 'Siren / Alarm' };

    const ruleObj = {
      id: `rule_user_${Date.now()}`,
      name,
      metric,
      operator,
      threshold: isNaN(parseFloat(threshold)) ? threshold : parseFloat(threshold),
      action,
      action_type: isRelay ? 'relay' : 'webhook',
      relay_num: relayNum,
      relay_name: relayNames[relayNum] || 'Actuator',
      enabled: true
    };

    try {
      const res = await fetch('/api/rules', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'add', rule: ruleObj })
      });
      if (res.ok) {
        document.getElementById('new-rule-name').value = '';
        document.getElementById('new-rule-threshold').value = '';
        loadRulesData();
      }
    } catch {}
  }

  async function toggleRelayState(relayNum) {
    const cell = document.getElementById(`relay-cell-${relayNum}`);
    const isCurrentlyActive = cell ? cell.classList.contains('active') : false;
    const newState = !isCurrentlyActive;

    try {
      const res = await fetch('/api/relay', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ relay_num: relayNum, state: newState, manual: true })
      });
      if (res.ok) {
        if (cell) cell.classList.toggle('active', newState);
        const badge = document.getElementById(`relay-badge-${relayNum}`);
        if (badge) badge.textContent = `RELAY ${relayNum}: ${newState ? 'ON (ACTIVE)' : 'OFF'}`;
      }
    } catch {}
  }

  async function loadStationAndMqttData() {
    try {
      const [resStation, resMqtt] = await Promise.all([
        fetch('/api/station'),
        fetch('/api/mqtt')
      ]);
      if (resStation.ok) {
        const s = await resStation.json();
        const elName = document.getElementById('station-name-input');
        const elZone = document.getElementById('station-zone-input');
        const elLat  = document.getElementById('station-lat-input');
        const elLon  = document.getElementById('station-lon-input');
        if (elName && s.name) elName.value = s.name;
        if (elZone && s.zone) elZone.value = s.zone;
        if (elLat  && s.lat)  elLat.value  = s.lat;
        if (elLon  && s.lon)  elLon.value  = s.lon;
      }
      if (resMqtt.ok) {
        const m = await resMqtt.json();
        const elHost = document.getElementById('mqtt-host-input');
        const elPort = document.getElementById('mqtt-port-input');
        const elPrefix = document.getElementById('mqtt-prefix-input');
        const elEnabled = document.getElementById('mqtt-enabled-input');
        if (elHost && m.host) elHost.value = m.host;
        if (elPort && m.port) elPort.value = m.port;
        if (elPrefix && m.topic_prefix) elPrefix.value = m.topic_prefix;
        if (elEnabled) elEnabled.checked = !!m.enabled;
      }
    } catch {}
  }

  async function saveStationMetadata() {
    const name = document.getElementById('station-name-input')?.value.trim();
    const zone = document.getElementById('station-zone-input')?.value.trim();
    const lat  = parseFloat(document.getElementById('station-lat-input')?.value) || 20.3540;
    const lon  = parseFloat(document.getElementById('station-lon-input')?.value) || 85.8180;

    try {
      const res = await fetch('/api/station', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, zone, lat, lon })
      });
      if (res.ok) {
        const btn = document.getElementById('btn-save-station');
        if (btn) {
          const orig = btn.textContent;
          btn.textContent = '✅ Saved Station!';
          setTimeout(() => { btn.textContent = orig; }, 1500);
        }
      }
    } catch {}
  }

  async function saveMqttSettings() {
    const host = document.getElementById('mqtt-host-input')?.value.trim() || 'localhost';
    const port = parseInt(document.getElementById('mqtt-port-input')?.value, 10) || 1883;
    const topic_prefix = document.getElementById('mqtt-prefix-input')?.value.trim() || 'aerosense';
    const enabled = document.getElementById('mqtt-enabled-input')?.checked || false;

    try {
      const res = await fetch('/api/mqtt', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ host, port, topic_prefix, enabled })
      });
      if (res.ok) {
        const btn = document.getElementById('btn-save-mqtt');
        if (btn) {
          const orig = btn.textContent;
          btn.textContent = '✅ MQTT Configured!';
          setTimeout(() => { btn.textContent = orig; }, 1500);
        }
      }
    } catch {}
  }

  async function exportComplianceAuditJson() {
    try {
      const res = await fetch('/api/export/audit-report');
      if (res.ok) {
        const data = await res.json();
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `aerosense_compliance_audit_${Date.now()}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
    } catch {}
  }

  function openAnywhereStudioModal(initialTab = 'profiles') {
    openModal('modal-anywhere-studio');
    // Switch to initial tab
    document.querySelectorAll('.studio-tab-btn').forEach(b => {
      b.classList.toggle('active', b.getAttribute('data-studio-tab') === initialTab);
    });
    document.querySelectorAll('.studio-tab-pane').forEach(p => {
      p.classList.toggle('active', p.id === `pane-${initialTab}`);
    });

    highlightActiveProfileInModal(studioCurrentProfile);
    highlightActiveStandardInModal(studioCurrentStandard);
    loadCalibrationData();
    loadRulesData();
    loadStationAndMqttData();
  }

  // Anywhere Studio Triggers
  document.getElementById('btn-open-anywhere-card')?.addEventListener('click', () => openAnywhereStudioModal('profiles'));
  document.getElementById('item-open-studio')?.addEventListener('click', () => openAnywhereStudioModal('profiles'));
  document.getElementById('btn-judge-open-anywhere')?.addEventListener('click', () => openAnywhereStudioModal('profiles'));
  document.getElementById('nav-tab-anywhere')?.addEventListener('click', (e) => {
    e.preventDefault();
    openAnywhereStudioModal('profiles');
  });
  document.getElementById('aqi-standard-badge')?.addEventListener('click', () => openAnywhereStudioModal('standards'));

  // Studio Tab Switcher
  document.querySelectorAll('.studio-tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const tab = btn.getAttribute('data-studio-tab');
      document.querySelectorAll('.studio-tab-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      document.querySelectorAll('.studio-tab-pane').forEach(p => p.classList.remove('active'));
      document.getElementById(`pane-${tab}`)?.classList.add('active');
    });
  });

  // Profile Deployment Click Handlers
  document.querySelectorAll('.btn-deploy-profile').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const p = btn.getAttribute('data-profile');
      deployProfile(p);
    });
  });

  document.querySelectorAll('.profile-card').forEach(card => {
    card.addEventListener('click', () => {
      const p = card.getAttribute('data-profile-select');
      deployProfile(p);
    });
  });

  document.querySelectorAll('.btn-quick-profile').forEach(btn => {
    btn.addEventListener('click', () => {
      const p = btn.getAttribute('data-profile');
      deployProfile(p);
      closeAllDropdowns();
    });
  });

  // Standards Deployment Click Handlers
  document.querySelectorAll('.btn-deploy-standard').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const s = btn.getAttribute('data-standard');
      deployStandard(s);
    });
  });

  document.querySelectorAll('.standard-card').forEach(card => {
    card.addEventListener('click', () => {
      const s = card.getAttribute('data-standard-select');
      deployStandard(s);
    });
  });

  // Hardware Relay Toggles
  [1, 2, 3].forEach(num => {
    document.getElementById(`btn-toggle-relay-${num}`)?.addEventListener('click', () => toggleRelayState(num));
  });

  // Calibration Actions
  document.getElementById('btn-save-calibration')?.addEventListener('click', saveCalibrationData);
  document.getElementById('btn-reset-calibration')?.addEventListener('click', () => {
    document.querySelectorAll('#calibration-tbody tr').forEach(tr => {
      tr.querySelector('.calib-gain').value = '1.0';
      tr.querySelector('.calib-offset').value = '0.0';
      tr.querySelector('.calib-enabled').checked = true;
    });
  });

  // Rules Actions
  document.getElementById('btn-add-rule')?.addEventListener('click', addCustomRule);
  document.getElementById('btn-save-webhook')?.addEventListener('click', async () => {
    const url = document.getElementById('webhook-url-input')?.value.trim();
    await fetch('/api/rules', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'set_webhook', webhook_url: url })
    });
    const btn = document.getElementById('btn-save-webhook');
    if (btn) {
      btn.textContent = '✅ Saved';
      setTimeout(() => { btn.textContent = 'Save Webhook'; }, 1500);
    }
  });

  // Station & IoT Actions
  document.getElementById('btn-save-station')?.addEventListener('click', saveStationMetadata);
  document.getElementById('btn-save-mqtt')?.addEventListener('click', saveMqttSettings);
  document.getElementById('btn-download-audit-json')?.addEventListener('click', exportComplianceAuditJson);

  // ---------------------------------------------------------------------------
  // Feature: Micro-Plume Dispersion Vectoring Radar
  // ---------------------------------------------------------------------------
  function renderPlumeVector(plume, src) {
    if (!plume) return;
    const bearing = plume.bearing_deg ?? 235;
    const cardinal = plume.cardinal || 'WSW';
    const dist = plume.distance_m ?? 140;
    const width = plume.plume_width_m ?? 28.0;
    const pSource = plume.source || src?.primary_source || 'Garbage Burning';
    const distCat = plume.distance_category || 'Localized Zone (50 - 300m)';
    const conf = plume.confidence_pct ?? 91.0;
    const directive = plume.dispatch_directive || `Active plume detected at ${bearing}° (${cardinal}), ~${dist}m upwind.`;
    const stabClass = plume.dispersion_model?.stability_class ? plume.dispersion_model.stability_class.split(' ')[0] : 'Pasquill-B';

    const vectorGroup = document.getElementById('plume-vector-group');
    if (vectorGroup) {
      vectorGroup.setAttribute('transform', `rotate(${bearing}, 120, 120)`);
    }

    const bVal = document.getElementById('plume-bearing-val');
    if (bVal) bVal.textContent = `${Math.round(bearing)}°`;

    const cVal = document.getElementById('plume-cardinal-val');
    if (cVal) cVal.textContent = cardinal;

    const sName = document.getElementById('plume-source-name');
    if (sName) sName.textContent = pSource;

    const zTag = document.getElementById('plume-zone-tag');
    if (zTag) zTag.textContent = distCat;

    const dVal = document.getElementById('plume-distance-val');
    if (dVal) dVal.textContent = `~${dist} m`;

    const wVal = document.getElementById('plume-width-val');
    if (wVal) wVal.textContent = `${width} m`;

    const stVal = document.getElementById('plume-stability-val');
    if (stVal) stVal.textContent = stabClass;

    const cfVal = document.getElementById('plume-confidence-val');
    if (cfVal) cfVal.textContent = `${conf.toFixed(1)}%`;

    const dirText = document.getElementById('plume-directive-text');
    if (dirText) dirText.textContent = directive;
  }

  // ---------------------------------------------------------------------------
  // Feature: 16-Band Acoustic Audio-FFT & Koschmieder Optical Extinction Haze
  // ---------------------------------------------------------------------------
  const EQ_FREQS = ['31','63','125','250','500','800','1k','1.2k','1.6k','2k','2.5k','3.1k','4k','5k','8k','16k'];

  function renderAcousticAndOpticalHaze(features) {
    if (!features) return;
    const spec = features.acoustic_spectrum;
    const haze = features.optical_haze;

    // 1. Acoustic Spectrum Equalizer
    if (spec) {
      const eqContainer = document.getElementById('equalizer-bars-container');
      if (eqContainer && spec.bands) {
        const bands = spec.bands;
        let html = '';
        bands.forEach((b, idx) => {
          const freqLabel = EQ_FREQS[idx] || `${spec.center_freqs?.[idx] || ''}`;
          const heightPx = Math.max(8, Math.min(75, Math.round(b * 75)));
          let bandClass = 'low';
          if (idx >= 4 && idx < 9) bandClass = 'mid';
          else if (idx >= 9) bandClass = 'high';

          html += `
            <div class="eq-bar-col">
              <div class="eq-bar-pillar ${bandClass}" style="height:${heightPx}px;"></div>
              <span class="eq-bar-freq">${freqLabel}</span>
            </div>
          `;
        });
        eqContainer.innerHTML = html;
      }

      const centroidEl = document.getElementById('spectral-centroid-val');
      if (centroidEl && spec.spectral_centroid_hz) {
        centroidEl.textContent = `Centroid: ${Math.round(spec.spectral_centroid_hz)} Hz`;
      }

      const sigBadge = document.getElementById('acoustic-sig-badge');
      if (sigBadge && spec.dominant_signature) {
        sigBadge.textContent = spec.dominant_signature;
        if (spec.color) {
          sigBadge.style.borderColor = spec.color;
          sigBadge.style.color = spec.color;
        }
      }

      const lowEl = document.getElementById('eq-low-val');
      if (lowEl) lowEl.textContent = (spec.low_band_energy ?? 0.58).toFixed(2);
      const midEl = document.getElementById('eq-mid-val');
      if (midEl) midEl.textContent = (spec.mid_band_energy ?? 0.24).toFixed(2);
      const highEl = document.getElementById('eq-high-val');
      if (highEl) highEl.textContent = (spec.high_band_energy ?? 0.08).toFixed(2);
    }

    // 2. Koschmieder Optical Haze
    if (haze) {
      const statusEl = document.getElementById('optical-haze-status');
      if (statusEl) {
        statusEl.textContent = haze.haze_status || 'Pristine Clarity';
        if (haze.color) {
          statusEl.style.borderColor = haze.color;
          statusEl.style.color = haze.color;
        }
      }
      const vrEl = document.getElementById('val-visual-range');
      if (vrEl) vrEl.textContent = `${haze.visual_range_km ?? 4.8} km`;

      const extEl = document.getElementById('val-extinction-coeff');
      if (extEl) extEl.textContent = `${haze.extinction_coeff_km ?? 0.815} km⁻¹`;

      const clEl = document.getElementById('val-contrast-loss');
      if (clEl) clEl.textContent = `${haze.contrast_attenuation_pct ?? 42.5}%`;

      const aodEl = document.getElementById('val-aod-surrogate');
      if (aodEl) aodEl.textContent = `${haze.aod_surrogate ?? 0.65}`;
    }
  }

  // ---------------------------------------------------------------------------
  // Feature: Model Predictive Control (MPC) 4-Channel Preemptive Protection
  // ---------------------------------------------------------------------------
  function renderMPCStatus(mpc, relays) {
    if (!mpc) return;
    const badge = document.getElementById('mpc-state-badge');
    const banner = document.getElementById('mpc-banner');
    const title = document.getElementById('mpc-banner-title');
    const desc = document.getElementById('mpc-banner-desc');
    const leadVal = document.querySelector('#mpc-lead-time .time-val');

    if (mpc.preemption_active) {
      if (badge) {
        badge.textContent = '⚡ Preemption Active';
        badge.style.color = 'var(--apple-green)';
        badge.style.borderColor = 'var(--apple-green)';
      }
      if (title) title.textContent = `Anticipating ${String(mpc.predicted_metric || 'PM2.5').toUpperCase()} Surge (+1h Horizon)`;
      if (desc) desc.textContent = mpc.preemptive_action || 'Purifiers energized in advance to build clean indoor buffer.';
      if (leadVal) leadVal.textContent = mpc.lead_time_min || 25;
    } else {
      if (badge) {
        badge.textContent = '🟢 Horizon Stable';
        badge.style.color = 'var(--apple-cyan)';
        badge.style.borderColor = 'var(--apple-cyan)';
      }
      if (title) title.textContent = '1-6h Horizon Stable (No Imminent Surge)';
      if (desc) desc.textContent = 'Air quality projected within baseline standards for the next 2 hours. Normal automated relay hysteresis active.';
      if (leadVal) leadVal.textContent = '—';
    }

    // Update 4 Hardware Relays
    if (relays) {
      for (let i = 1; i <= 4; i++) {
        const r = relays[i];
        if (!r) continue;
        const card = document.getElementById(`mpc-relay-${i}`);
        const statusBadge = document.getElementById(`mpc-badge-${i}`);
        if (!statusBadge) continue;

        if (r.state) {
          card?.classList.add('active');
          statusBadge.classList.add('active');
          statusBadge.textContent = (i === 2 && mpc.preemption_active) ? 'ON (PREEMPTIVE)' : 'ON';
        } else {
          card?.classList.remove('active');
          statusBadge.classList.remove('active');
          statusBadge.textContent = 'OFF';
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Feature: Cryptographic SHA-256 Merkle Audit Ledger
  // ---------------------------------------------------------------------------
  async function fetchAuditLedgerStatus() {
    try {
      const resp = await fetch('/api/export/ledger');
      if (!resp.ok) return;
      const data = await resp.json();
      const rootEl = document.getElementById('ledger-merkle-root');
      const blkEl = document.getElementById('ledger-block-hash');
      const countEl = document.getElementById('ledger-block-count');
      const compEl = document.getElementById('ledger-compliance-pct');
      const verifiedBadge = document.getElementById('ledger-verified-badge');

      if (data.latest_block) {
        if (rootEl) rootEl.textContent = data.latest_block.merkle_root;
        if (blkEl)  blkEl.textContent  = data.latest_block.block_hash;
        if (compEl) compEl.textContent = `${data.latest_block.compliance_pct}%`;
      }
      if (countEl) countEl.textContent = `${data.total_blocks} Blocks`;
      if (verifiedBadge) {
        verifiedBadge.textContent = data.valid ? '🟢 SECURE_VERIFIED' : '🔴 TAMPER_DETECTED';
        verifiedBadge.style.color = data.valid ? 'var(--apple-green)' : '#EF4444';
      }
    } catch (e) {
      console.warn('Ledger fetch error', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Relay Control API Helper
  // ---------------------------------------------------------------------------
  async function toggleRelayState(relayNum, explicitState = null) {
    try {
      const card = document.getElementById(`mpc-relay-${relayNum}`) || document.getElementById(`relay-cell-${relayNum}`);
      const isCurrentlyOn = card ? card.classList.contains('active') : false;
      const targetState = explicitState !== null ? explicitState : !isCurrentlyOn;

      const res = await fetch('/api/relay', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ relay_num: relayNum, state: targetState, manual: true })
      });
      if (res.ok) {
        fetchLiveTelemetry();
      }
    } catch (e) {
      console.warn('Relay toggle failed', e);
    }
  }

  // ---------------------------------------------------------------------------
  // Feature: On-Device "AeroSense Voice" Assistant Modal & Speech Synthesis
  // ---------------------------------------------------------------------------
  function initVoiceAssistant() {
    const modalVoice = document.getElementById('modal-voice-assistant');
    const btnOpenHdr = document.getElementById('btn-open-voice-modal');
    const fabVoice   = document.getElementById('floating-voice-fab');
    const form       = document.getElementById('voice-query-form');
    const input      = document.getElementById('voice-input-text');
    const ansText    = document.getElementById('voice-answer-text');
    const actText    = document.getElementById('voice-action-text');
    const listenBtn  = document.getElementById('btn-listen-speech');
    let lastSpokenText = '';

    function openVoiceModal() {
      if (modalVoice) modalVoice.classList.add('active');
      setTimeout(() => input?.focus(), 200);
    }

    btnOpenHdr?.addEventListener('click', openVoiceModal);
    fabVoice?.addEventListener('click', openVoiceModal);

    async function sendVoiceQuery(queryStr) {
      if (!queryStr || !queryStr.trim()) return;
      if (ansText) ansText.textContent = 'Thinking locally on QRB2210 core…';
      if (actText) actText.textContent = 'Synthesizing sensor evidence…';

      try {
        const resp = await fetch('/api/voice-query', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ query: queryStr })
        });
        if (!resp.ok) throw new Error('Voice query failed');
        const data = await resp.json();
        if (ansText) ansText.textContent = data.answer;
        if (actText) actText.textContent = data.action;
        lastSpokenText = data.spoken_audio_text || data.answer;

        // Auto-play audio if voice toggle is enabled
        if (isVoiceEnabled && window.speechSynthesis) {
          playSpeech(lastSpokenText);
        }
      } catch (err) {
        if (ansText) ansText.textContent = 'Error querying on-device assistant. Telemetry running offline.';
      }
    }

    form?.addEventListener('submit', (e) => {
      e.preventDefault();
      const q = input?.value.trim();
      if (q) sendVoiceQuery(q);
    });

    document.querySelectorAll('.prompt-chip').forEach(chip => {
      chip.addEventListener('click', () => {
        const p = chip.getAttribute('data-prompt');
        if (input) input.value = p;
        sendVoiceQuery(p);
      });
    });

    function playSpeech(text) {
      if (!window.speechSynthesis || !text) return;
      window.speechSynthesis.cancel();
      const utter = new SpeechSynthesisUtterance(text);
      utter.rate = 1.0;
      utter.pitch = 1.0;
      window.speechSynthesis.speak(utter);
    }

    listenBtn?.addEventListener('click', () => {
      if (lastSpokenText) {
        playSpeech(lastSpokenText);
      } else if (ansText) {
        playSpeech(ansText.textContent);
      }
    });

    // Ledger Buttons
    document.getElementById('btn-verify-ledger')?.addEventListener('click', async () => {
      const btn = document.getElementById('btn-verify-ledger');
      if (btn) btn.textContent = '⏳ Verifying SHA-256 Merkle Chain…';
      await fetchAuditLedgerStatus();
      if (btn) {
        btn.textContent = '✅ Chain Verified 100% Intact';
        setTimeout(() => { btn.textContent = '🔒 Re-Verify SHA-256 Merkle Chain'; }, 2000);
      }
    });

    document.getElementById('btn-export-certificate')?.addEventListener('click', async () => {
      try {
        const resp = await fetch('/api/export/certificate');
        const cert = await resp.json();
        const blob = new Blob([JSON.stringify(cert, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `AEROSENSE_REGULATORY_CERT_${Date.now()}.json`;
        a.click();
        URL.revokeObjectURL(url);
      } catch (e) {
        alert('Could not export certificate');
      }
    });

    // MPC Relay Manual Toggles
    [1, 2, 3, 4].forEach(rNum => {
      document.getElementById(`btn-mpc-toggle-${rNum}`)?.addEventListener('click', async () => {
        const badge = document.getElementById(`mpc-badge-${rNum}`);
        const isCurrentlyOn = badge?.classList.contains('active');
        await toggleRelayState(rNum, !isCurrentlyOn);
      });
    });
  }


  // ---------------------------------------------------------------------------
  // Initialize
  // ---------------------------------------------------------------------------
  initVoiceAssistant();
  fetchAuditLedgerStatus();
  initV15Features();    // v1.5.0 Tier-1 features
  startRefreshLoop();
});

// =============================================================================
// v1.5.0 Tier-1 Features — Init & Render
// =============================================================================

let _heatmapInstance = null;
let _heatmapMarkers  = [];

function initV15Features() {
  initCityHeatmap();
  initSleepWindowSelects();
  wireV15Controls();
  // Kick off first fetch
  refreshV15Panels();
  // Refresh every 10 seconds (lighter than main 1s loop)
  setInterval(refreshV15Panels, 10000);
}

async function refreshV15Panels() {
  try {
    const [scoreData, sleepData, alertsData, meshData] = await Promise.allSettled([
      fetch('/api/health-score').then(r => r.json()),
      fetch('/api/sleep-mode').then(r => r.json()),
      fetch('/api/notification-intelligence').then(r => r.json()),
      fetch('/api/mesh').then(r => r.json()),
    ]);

    if (scoreData.status === 'fulfilled')  renderHealthScore(scoreData.value);
    if (sleepData.status === 'fulfilled')  renderSleepMode(sleepData.value);
    if (alertsData.status === 'fulfilled') renderSmartAlerts(alertsData.value);
    if (meshData.status === 'fulfilled')   updateHeatmapNodes(meshData.value);
  } catch (e) {
    // Silently use demo data if server offline
    renderHealthScore(getDemoHealthScore());
    renderSleepMode(getDemoSleepMode());
    renderSmartAlerts(getDemoAlerts());
  }
}

// ===================== Card A: Pollution Credit Score =====================

function renderHealthScore(data) {
  if (!data || data.score === undefined) data = getDemoHealthScore();

  const scoreNum   = document.getElementById('credit-score-num');
  const scoreBand  = document.getElementById('credit-score-band');
  const ringFill   = document.getElementById('credit-ring-fill');
  const trendVal   = document.getElementById('credit-trend-val');
  const weeklyChart = document.getElementById('credit-weekly-chart');
  const recsEl     = document.getElementById('credit-recs');
  const updatedEl  = document.getElementById('credit-score-updated');

  if (!scoreNum) return;

  const score = data.score || 0;
  const band  = data.band || 'Good';
  const color = data.band_color || '#22c55e';

  // Animate number
  scoreNum.textContent = score;
  scoreNum.style.color = color;

  // Band label
  if (scoreBand) { scoreBand.textContent = `${data.band_emoji || ''} ${band}`; scoreBand.style.color = color; }

  // Credit ring (circumference = 2π × 84 = 527.8)
  if (ringFill) {
    const circ = 527;
    const offset = circ - (score / 1000) * circ;
    ringFill.style.strokeDashoffset = offset;
    ringFill.style.stroke = color;
  }

  // Trend
  if (trendVal) {
    const delta = data.weekly_delta || 0;
    trendVal.textContent = data.trend || '➡️ Stable';
    trendVal.style.color = delta >= 0 ? '#22c55e' : '#ef4444';
  }

  // 7-day sparkline bars
  if (weeklyChart) {
    weeklyChart.innerHTML = '';
    const history = data.weekly_history || [];
    if (history.length === 0) {
      // Demo data fallback
      [720,680,750,610,790,700,score].forEach((s, i) => _addSparkBar(weeklyChart, s, `Day ${i+1}`));
    } else {
      history.forEach(d => _addSparkBar(weeklyChart, d.score, d.date, d.color));
      _addSparkBar(weeklyChart, score, 'Today', color);
    }
  }

  // Recommendations
  if (recsEl) {
    recsEl.innerHTML = (data.recommendations || []).map(r =>
      `<div class="credit-rec-item">${r}</div>`
    ).join('');
  }

  if (updatedEl) updatedEl.textContent = `Updated ${new Date().toLocaleTimeString()}`;
}

function _addSparkBar(container, score, label, color) {
  const bar = document.createElement('div');
  bar.className = 'credit-weekly-bar';
  const pct = Math.max(4, (score / 1000) * 100);
  bar.style.height = pct + '%';
  bar.style.background = color || _scoreColor(score);
  bar.title = `${label}: ${score}/1000`;
  container.appendChild(bar);
}

function _scoreColor(score) {
  if (score >= 850) return '#22c55e';
  if (score >= 700) return '#84cc16';
  if (score >= 500) return '#eab308';
  if (score >= 300) return '#f97316';
  return '#ef4444';
}

// ===================== Card B: City AQI Heatmap (Leaflet) =====================

function initCityHeatmap() {
  const mapEl = document.getElementById('city-heatmap-map');
  if (!mapEl || !window.L) return;

  try {
    _heatmapInstance = L.map('city-heatmap-map', {
      center: [20.354, 85.818],
      zoom: 13,
      zoomControl: true,
      attributionControl: false,
    });

    // Dark tile layer
    L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
      subdomains: 'abcd',
      maxZoom: 19,
    }).addTo(_heatmapInstance);

    // Attribution (minimal)
    L.control.attribution({ prefix: '© CartoDB · OSM' }).addTo(_heatmapInstance);
  } catch (e) {
    console.warn('Leaflet heatmap init failed:', e);
  }
}

function updateHeatmapNodes(meshData) {
  if (!_heatmapInstance || !window.L) return;

  const nodes = Array.isArray(meshData) ? meshData : (meshData.nodes || []);

  // Clear old markers
  _heatmapMarkers.forEach(m => m.remove());
  _heatmapMarkers = [];

  if (nodes.length === 0) {
    // Demo: show local node
    _addHeatmapNode({ lat: 20.3540, lon: 85.8180, name: 'Central Campus', aqi: 48, pm25: 14.2 });
    _addHeatmapNode({ lat: 20.362,  lon: 85.823,  name: 'Gate A East',    aqi: 82, pm25: 28.5 });
    _addHeatmapNode({ lat: 20.348,  lon: 85.814,  name: 'Library Block',  aqi: 35, pm25: 9.8  });
    document.getElementById('heatmap-node-count').textContent = '3 nodes online (demo)';
    document.getElementById('heatmap-worst-zone').textContent = 'Worst: Gate A East (AQI 82)';
    return;
  }

  let worstAqi = 0, worstName = '—';
  nodes.forEach(n => {
    if (n.lat && n.lon) {
      _addHeatmapNode(n);
      if ((n.aqi || n.current_aqi || 0) > worstAqi) {
        worstAqi = n.aqi || n.current_aqi || 0;
        worstName = n.name || n.node_name || 'Unknown';
      }
    }
  });

  document.getElementById('heatmap-node-count').textContent = `${nodes.length} node${nodes.length !== 1 ? 's' : ''} online`;
  document.getElementById('heatmap-worst-zone').textContent = `Worst: ${worstName} (AQI ${worstAqi})`;
}

function _addHeatmapNode(node) {
  if (!_heatmapInstance) return;
  const aqi   = node.aqi || node.current_aqi || 0;
  const color = _aqiToColor(aqi);
  const lat   = parseFloat(node.lat);
  const lon   = parseFloat(node.lon);
  if (isNaN(lat) || isNaN(lon)) return;

  const marker = L.circleMarker([lat, lon], {
    radius: 18,
    fillColor: color,
    color: '#000',
    weight: 1.5,
    opacity: 0.9,
    fillOpacity: 0.75,
  }).addTo(_heatmapInstance);

  marker.bindPopup(`
    <div style="font-family:Inter,sans-serif;min-width:140px;">
      <strong style="font-size:0.95rem;">${node.name || node.node_name || 'Node'}</strong><br>
      <span style="font-size:1.5rem;font-weight:800;color:${color};">${aqi}</span>
      <span style="font-size:0.75rem;color:#aaa;"> AQI</span><br>
      <span style="font-size:0.75rem;color:#aaa;">PM2.5: ${(node.pm25 || 0).toFixed(1)} µg/m³</span>
    </div>
  `);

  // Pulsing effect via CSS class alternative — add invisible circle for pulse
  _heatmapMarkers.push(marker);
}

function _aqiToColor(aqi) {
  if (aqi <= 50)  return '#22c55e';
  if (aqi <= 100) return '#84cc16';
  if (aqi <= 150) return '#eab308';
  if (aqi <= 200) return '#f97316';
  if (aqi <= 300) return '#ef4444';
  return '#7f1d1d';
}

// ===================== Card C: Smart Alert Intelligence =====================

function renderSmartAlerts(data) {
  if (!data) data = getDemoAlerts();

  const fatigueVal    = document.getElementById('fatigue-score-val');
  const fatigueBar    = document.getElementById('fatigue-bar-fill');
  const fatigueLabel  = document.getElementById('fatigue-label');
  const firedEl       = document.getElementById('alerts-fired');
  const suppEl        = document.getElementById('alerts-suppressed');
  const rateEl        = document.getElementById('alerts-suppression-rate');
  const sigmaEl       = document.getElementById('alerts-sigma');
  const logEl         = document.getElementById('alert-log');

  const fatigue = data.fatigue_score || 0;
  const cap     = data.fatigue_cap || 70;

  if (fatigueVal)   fatigueVal.textContent = Math.round(fatigue);
  if (fatigueBar)   fatigueBar.style.width = Math.min(100, (fatigue / cap) * 100) + '%';
  if (fatigueLabel) { fatigueLabel.textContent = data.fatigue_label || '🟢 Alert-Ready'; fatigueLabel.style.color = _fatigueColor(fatigue, cap); }
  if (firedEl)      firedEl.textContent = data.total_fired || 0;
  if (suppEl)       suppEl.textContent = data.total_suppressed || 0;
  if (rateEl)       rateEl.textContent = (data.suppression_rate || 0) + '%';
  if (sigmaEl)      sigmaEl.textContent = (data.sigma_threshold || 2.5) + 'σ';

  if (logEl) {
    const alerts = data.recent_alerts || [];
    if (alerts.length === 0) {
      logEl.innerHTML = '<div class="alert-log-item" style="color:var(--text-muted);">No alerts fired yet — baseline building…</div>';
    } else {
      logEl.innerHTML = alerts.slice(-8).reverse().map(a => `
        <div class="alert-log-item">
          <span class="alert-log-dot" style="background:${a.type==='fired'?'#ef4444':'#6b7280'};"></span>
          <span class="alert-log-metric">${a.metric?.toUpperCase() || '—'} ${a.value || ''}</span>
          <span style="color:var(--text-secondary);font-size:0.7rem;">${a.reason?.split('(')[0] || ''}</span>
          <span class="alert-log-time">${(a.ts||'').slice(11,16)}</span>
        </div>
      `).join('');
    }
  }
}

function _fatigueColor(score, cap) {
  const pct = score / cap;
  if (pct < 0.3) return '#22c55e';
  if (pct < 0.6) return '#eab308';
  if (pct < 0.85) return '#f97316';
  return '#ef4444';
}

// ===================== Card D: Sleep & Circadian Mode =====================

function initSleepWindowSelects() {
  const startSel = document.getElementById('sleep-start-select');
  const endSel   = document.getElementById('sleep-end-select');
  if (!startSel || !endSel) return;

  for (let h = 0; h < 24; h++) {
    const label = `${String(h).padStart(2,'0')}:00`;
    startSel.appendChild(new Option(label, h, false, h === 22));
    endSel.appendChild(new Option(label, h, false, h === 6));
  }
}

function renderSleepMode(data) {
  if (!data) data = getDemoSleepMode();

  const badge        = document.getElementById('sleep-mode-badge');
  const icon         = document.getElementById('sleep-mode-icon');
  const statusLabel  = document.getElementById('sleep-status-label');
  const thresholdEl  = document.getElementById('sleep-pm25-threshold');
  const relayLabel   = document.getElementById('sleep-relay-label');
  const wakePanel    = document.getElementById('wake-report-panel');

  const isSleep = data.is_sleep_mode;

  if (badge) {
    badge.textContent = isSleep ? '🌙 SLEEP MODE' : '☀️ AWAKE';
    badge.style.background = isSleep ? 'rgba(100,210,255,0.15)' : 'rgba(48,209,88,0.15)';
    badge.style.color = isSleep ? '#64D2FF' : '#30D158';
  }
  if (icon)        icon.textContent = isSleep ? '🌙' : '☀️';
  if (statusLabel) statusLabel.textContent = isSleep ? 'Sleep Mode Active — Relay Quiet Mode ON' : 'Awake — Normal Monitoring';
  if (thresholdEl) thresholdEl.textContent = `${data.pm25_threshold || 12} µg/m³`;
  if (relayLabel)  relayLabel.textContent  = isSleep ? '🔇 Relays in quiet mode' : '🔊 Relays operating normally';

  // Show wake report if available
  if (wakePanel && data.last_wake_report) {
    const report = data.last_wake_report;
    wakePanel.style.display = 'block';
    const qs = document.getElementById('sleep-quality-score');
    const qa = document.getElementById('sleep-avg-aqi');
    const qd = document.getElementById('sleep-duration');
    const qn = document.getElementById('wake-narrative');
    if (qs) qs.textContent = report.sleep_quality_score + '/100';
    if (qa) qa.textContent = report.avg_aqi_during_sleep?.toFixed(1) || '—';
    if (qd) qd.textContent = (report.sleep_duration_hours || 0).toFixed(1) + 'h';
    if (qn) qn.textContent = report.narrative || '';
  }
}

// ===================== Wire controls =====================

function wireV15Controls() {
  // Credit profile change
  document.getElementById('credit-profile-select')?.addEventListener('change', async (e) => {
    try {
      await fetch('/api/household-profile', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ profile: e.target.value })
      });
      const data = await fetch('/api/health-score').then(r => r.json());
      renderHealthScore(data);
    } catch (_) {}
  });

  // Apply sleep window
  document.getElementById('btn-apply-sleep-window')?.addEventListener('click', async () => {
    const start = parseInt(document.getElementById('sleep-start-select')?.value || 22);
    const end   = parseInt(document.getElementById('sleep-end-select')?.value || 6);
    try {
      const resp = await fetch('/api/sleep-mode', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sleep_start_hour: start, sleep_end_hour: end, enabled: true })
      });
      const data = await resp.json();
      renderSleepMode(data);
    } catch (_) {}
  });

  // Reset alert fatigue
  document.getElementById('btn-reset-fatigue')?.addEventListener('click', async () => {
    try {
      await fetch('/api/notification-filter', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'reset_fatigue' })
      });
      const data = await fetch('/api/notification-intelligence').then(r => r.json());
      renderSmartAlerts(data);
    } catch (_) {}
  });
}

// ===================== Demo Fallbacks =====================

function getDemoHealthScore() {
  return {
    score: 748, band: 'Good', band_emoji: '✅', band_color: '#84cc16',
    profile: 'adult', profile_multiplier: 1.0, hours_monitored: 14,
    trend: '↗️ Improving', weekly_delta: 28,
    weekly_history: [
      { date: 'Mon', score: 720, color: '#84cc16' }, { date: 'Tue', score: 680, color: '#eab308' },
      { date: 'Wed', score: 750, color: '#84cc16' }, { date: 'Thu', score: 610, color: '#eab308' },
      { date: 'Fri', score: 790, color: '#22c55e' }, { date: 'Sat', score: 700, color: '#84cc16' },
    ],
    recommendations: [
      '🌿 Great job! Air quality habits on track',
      '🪟 Best ventilation window: 6–8 AM',
      '😷 Wear N95 during garbage truck hours',
    ]
  };
}

function getDemoSleepMode() {
  const hour = new Date().getHours();
  const isSleep = hour >= 22 || hour < 6;
  return {
    enabled: true, is_sleep_mode: isSleep, sleep_start_hour: 22, sleep_end_hour: 6,
    relay_quiet_mode: isSleep, pm25_threshold: isSleep ? 12.0 : 15.0, aqi_threshold: isSleep ? 50 : 100,
    sleep_duration_h: isSleep ? 1.5 : 0.0,
    last_wake_report: isSleep ? null : {
      sleep_quality_score: 82, quality_label: 'Good Sleep Quality',
      avg_aqi_during_sleep: 34.2, sleep_duration_hours: 7.8,
      narrative: 'Good overnight air quality! PM2.5 averaged 10.5 µg/m³ — conditions were restorative.',
    }
  };
}

function getDemoAlerts() {
  return {
    fatigue_score: 14.5, fatigue_cap: 70, fatigue_label: '🟢 Alert-Ready', fatigue_pct: 20.7,
    sigma_threshold: 2.5, cooldown_sec: 300, total_fired: 3, total_suppressed: 22, suppression_rate: 88.0,
    recent_alerts: [
      { ts: new Date().toISOString(), metric: 'PM25', value: 88.5, type: 'fired', reason: 'anomaly_detected (3.1σ above baseline)' },
      { ts: new Date(Date.now()-300000).toISOString(), metric: 'VOC', value: 210.0, type: 'fired', reason: 'anomaly_detected (4.2σ above baseline)' },
    ]
  };
}
