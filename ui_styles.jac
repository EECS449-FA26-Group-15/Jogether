"""Shared styles for the Jogether planner; no external font or asset requests."""

glob APP_STYLES: str = """
body { margin: 0; }
.jogether { --ink: #183e33; --muted: #5f7069; --line: #dce3db; --cream: #f7f8f2; --lime: #d7ee9d; color: var(--ink); background: var(--cream); font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; min-height: 100vh; }
.jogether * { box-sizing: border-box; }
.jogether a { color: inherit; }
.jogether button, .jogether input, .jogether select, .jogether textarea { font: inherit; }
.jogether button, .jogether a, .jogether input, .jogether select, .jogether textarea { -webkit-tap-highlight-color: transparent; }
.jogether :focus-visible { outline: 3px solid #628a2c; outline-offset: 4px; }
.jogether .shell { width: min(1120px, calc(100% - 64px)); margin: 0 auto; }
.jogether .site-header { display: flex; align-items: center; justify-content: space-between; min-height: 90px; border-bottom: 1px solid var(--line); gap: 24px; }
.jogether .brand { display: flex; align-items: center; text-decoration: none; font-size: 27px; font-weight: 800; letter-spacing: -1.3px; }
.jogether .brand-mark { display: grid; place-items: center; width: 35px; height: 35px; background: var(--ink); color: var(--lime); border-radius: 50%; margin-right: 10px; font-size: 29px; padding-bottom: 5px; }
.jogether .brand-dot { color: #6a8c31; }
.jogether nav { display: flex; gap: 32px; font-size: 14px; font-weight: 600; }
.jogether nav a { text-decoration: none; padding: 12px 0; }
.jogether nav a:hover { text-decoration: underline; text-underline-offset: 6px; }
.jogether .location { font-size: 12px; letter-spacing: .5px; }
.jogether .location span { margin-left: 12px; }
.jogether .intro { display: flex; align-items: flex-end; justify-content: space-between; gap: 48px; padding: 46px 0 38px; }
.jogether .eyebrow { font-size: 10px; font-weight: 750; letter-spacing: 1.7px; text-transform: uppercase; margin: 0 0 16px; }
.jogether h1 { font-size: clamp(42px, 4.4vw, 60px); line-height: 1.06; font-weight: 750; letter-spacing: -2.6px; margin: 0; }
.jogether h1 em { font-family: Georgia, serif; font-weight: 400; color: #66823f; }
.jogether .intro-copy { max-width: 290px; color: var(--muted); font-size: 15px; line-height: 1.7; margin: 0 0 4px; }
.jogether .planner-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; align-items: start; scroll-margin-top: 24px; }
.jogether .form-panel { background: white; border: 1px solid var(--line); border-radius: 20px; padding: 30px; box-shadow: 0 8px 28px #183e3305; }
.jogether .panel-heading { display: flex; justify-content: space-between; align-items: center; gap: 12px; margin-bottom: 28px; }
.jogether .panel-heading .eyebrow { margin-bottom: 9px; color: var(--muted); }
.jogether h2 { margin: 0; font-size: 24px; letter-spacing: -.7px; line-height: 1.25; }
.jogether .heading-icon { display: grid; place-items: center; flex-shrink: 0; background: var(--cream); border-radius: 50%; width: 42px; height: 42px; font-size: 25px; }
.jogether .fields { border: 0; padding: 0; margin: 0; display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); column-gap: 18px; row-gap: 22px; min-width: 0; }
.jogether .field { min-width: 0; }
.jogether label { display: block; font-size: 12px; font-weight: 700; margin-bottom: 9px; }
.jogether input, .jogether select, .jogether textarea { width: 100%; min-width: 0; border: 1px solid var(--line); border-radius: 9px; color: var(--ink); background: #fcfdf9; padding: 13px 12px; font-size: 14px; line-height: 1.3; }
.jogether input, .jogether select { height: 47px; }
.jogether textarea { resize: vertical; min-height: 94px; }
.jogether textarea::placeholder { color: #758078; font-size: 13px; }
.jogether .distance-input { display: grid; grid-template-columns: minmax(0, 1fr) 85px; gap: 7px; }
.jogether .field-hint { display: block; color: var(--muted); font-size: 10px; line-height: 1.5; margin-top: 7px; }
.jogether .full-width { grid-column: 1 / -1; }
.jogether .optional { float: right; color: var(--muted); font-weight: 400; font-size: 11px; }
.jogether .primary-button, .jogether .maps-button { display: flex; width: 100%; align-items: center; justify-content: space-between; gap: 12px; border: 0; border-radius: 10px; background: var(--ink); color: white; min-height: 52px; padding: 14px 18px; font-size: 14px; font-weight: 650; cursor: pointer; text-decoration: none; }
.jogether .primary-button { margin-top: 23px; }
.jogether .primary-button span, .jogether .maps-button span { font-size: 23px; color: var(--lime); }
.jogether .primary-button:hover, .jogether .maps-button:hover { background: #2e5948; }
.jogether button:disabled, .jogether fieldset:disabled { opacity: .65; }
.jogether button:disabled { cursor: wait; }
.jogether .example-button { display: block; background: transparent; border: 0; color: var(--muted); font-size: 11px; padding: 15px 0 0; min-height: 42px; width: 100%; text-decoration: underline; text-underline-offset: 3px; cursor: pointer; }
.jogether .result-panel { border-radius: 20px; background: #eaf0df; border: 1px solid #dce5d0; overflow: hidden; min-width: 0; }
.jogether .empty-state { min-height: 532px; padding: 32px 42px; display: flex; flex-direction: column; justify-content: center; align-items: center; text-align: center; }
.jogether .empty-state .eyebrow { color: #516643; }
.jogether .route-art { width: min(100%, 320px); height: 210px; margin: 0 0 16px; }
.jogether .track-line { stroke: #183e33; stroke-width: 2; stroke-linecap: round; }
.jogether .track-inner { stroke: #8da77b; stroke-width: 1; stroke-dasharray: 4 6; }
.jogether .empty-state h2 { font-family: Georgia, serif; font-weight: 400; font-size: 32px; line-height: 1.12; }
.jogether .empty-state > p:not(.eyebrow) { max-width: 310px; font-size: 13px; line-height: 1.65; color: #51634b; margin: 18px 0; }
.jogether .empty-caption { font-size: 10px; color: #51634b; margin-top: 6px; }
.jogether .spinner { width: 44px; height: 44px; border: 3px solid #cedac0; border-top-color: var(--ink); border-radius: 50%; animation: jog-spin 1s linear infinite; margin-bottom: 32px; }
@keyframes jog-spin { to { transform: rotate(360deg); } }
.jogether .error-state { padding: 40px; min-height: 300px; background: #fff6e9; }
.jogether .error-state .eyebrow { color: #8f542c; }
.jogether .error-state p, .jogether .error-state li { font-size: 14px; line-height: 1.7; }
.jogether .error-state ul { padding-left: 20px; }
.jogether .route-card { background: white; padding: 30px; }
.jogether .route-heading { background: var(--ink); color: white; padding: 28px 30px; margin: -30px -30px 24px; }
.jogether .route-heading .eyebrow { color: var(--lime); font-size: 9px; }
.jogether .route-heading h2 { font-size: 28px; }
.jogether .route-heading > p:last-child { color: #ccd9d0; line-height: 1.5; font-size: 11px; margin-bottom: 0; }
.jogether .route-stats { display: grid; grid-template-columns: repeat(3, 1fr); margin: 0; padding-bottom: 18px; border-bottom: 1px solid var(--line); }
.jogether .route-stats div + div { border-left: 1px solid var(--line); padding-left: 20px; }
.jogether dt { color: var(--muted); font-size: 11px; margin-bottom: 6px; }
.jogether dd { font-size: 29px; letter-spacing: -1px; font-weight: 700; margin: 0; }
.jogether dd span { font-size: 12px; letter-spacing: 0; font-weight: 400; padding-left: 5px; }
.jogether .difficulty-reason { color: var(--muted); font-size: 12px; line-height: 1.6; margin: 16px 0 22px; }
.jogether .stops-title, .jogether .safety-notes h3 { font-size: 12px; margin: 0 0 14px; }
.jogether .waypoints { list-style: none; margin: 0 0 20px; padding: 0; }
.jogether .waypoints li { display: flex; gap: 13px; position: relative; padding-bottom: 17px; }
.jogether .waypoints li:not(:last-child)::before { content: ''; position: absolute; border-left: 1px solid var(--line); top: 27px; bottom: 0; left: 13px; }
.jogether .stop-number { flex-shrink: 0; display: grid; place-items: center; width: 27px; height: 27px; border-radius: 50%; background: #edf3e5; font-size: 10px; font-weight: 700; }
.jogether .waypoints strong { display: block; font-size: 13px; padding-top: 4px; }
.jogether .waypoints p { font-size: 11px; line-height: 1.6; color: var(--muted); margin: 4px 0 0; }
.jogether .safety-notes { background: #f7f3e8; border-radius: 10px; padding: 16px; margin-bottom: 20px; }
.jogether .safety-notes h3 { margin-bottom: 8px; }
.jogether .safety-notes ul { font-size: 11px; color: #6b624a; line-height: 1.7; padding-left: 16px; margin: 0; }
.jogether .maps-button { font-size: 12px; }
.jogether .lap-note { font-size: 11px; color: var(--muted); line-height: 1.5; }
.jogether .how-it-works { padding: 52px 0 40px; }
.jogether .how-it-works > h2 { font-size: 21px; }
.jogether .steps { display: grid; grid-template-columns: repeat(3, 1fr); gap: 38px; margin-top: 28px; }
.jogether .steps > div { position: relative; padding-left: 36px; }
.jogether .steps span { position: absolute; left: 0; top: 2px; color: #798b63; font-size: 11px; }
.jogether .steps h3 { font-size: 13px; margin: 0 0 8px; }
.jogether .steps p { color: var(--muted); font-size: 12px; line-height: 1.65; margin: 0; }
.jogether footer { display: flex; justify-content: space-between; align-items: center; gap: 18px; border-top: 1px solid var(--line); padding: 24px 0; color: var(--muted); font-size: 10px; }
.jogether .footer-brand { color: var(--ink); font-weight: 800; font-size: 17px; letter-spacing: -.7px; }
.jogether .sr-only, .jogether .skip-link:not(:focus) { position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0, 0, 0, 0); white-space: nowrap; border: 0; }
.jogether .skip-link:focus { display: block; padding: 12px; background: var(--lime); }
@media (max-width: 800px) {
    .jogether .shell { width: calc(100% - 40px); }
    .jogether .location { display: none; }
    .jogether .intro { gap: 24px; padding-top: 32px; }
    .jogether .intro-copy { max-width: 220px; font-size: 13px; }
    .jogether .planner-grid { grid-template-columns: 1fr; }
    .jogether .empty-state { min-height: 380px; }
    .jogether .route-art { height: 150px; }
}
@media (max-width: 520px) {
    .jogether .shell { width: calc(100% - 32px); }
    .jogether .site-header { min-height: 76px; gap: 12px; }
    .jogether .brand { font-size: 23px; }
    .jogether .brand-mark { width: 30px; height: 30px; font-size: 25px; margin-right: 6px; }
    .jogether nav { gap: 15px; font-size: 11px; }
    .jogether .intro { display: block; padding: 30px 0; }
    .jogether h1 { font-size: 42px; letter-spacing: -1.8px; }
    .jogether .intro-copy { max-width: 310px; margin-top: 20px; }
    .jogether .eyebrow { font-size: 9px; letter-spacing: 1.2px; }
    .jogether .form-panel, .jogether .route-card { padding: 22px; }
    .jogether .panel-heading h2 { font-size: 21px; }
    .jogether .heading-icon { width: 32px; height: 32px; }
    .jogether .fields { column-gap: 12px; row-gap: 20px; }
    .jogether input, .jogether select, .jogether textarea { font-size: 16px; padding: 11px 9px; }
    .jogether .distance-input { grid-template-columns: minmax(0, 1fr) 72px; gap: 5px; }
    .jogether .route-heading { margin: -22px -22px 22px; padding: 25px 22px; }
    .jogether .empty-state { padding: 30px; }
    .jogether .steps { grid-template-columns: 1fr; gap: 24px; }
    .jogether .how-it-works { padding: 38px 0; }
    .jogether footer { flex-wrap: wrap; justify-content: flex-start; gap: 10px 20px; }
}
@media (max-width: 360px) {
    .jogether .fields { grid-template-columns: 1fr; }
    .jogether nav { gap: 10px; font-size: 10px; }
    .jogether h1 { font-size: 37px; }
}
@media (prefers-reduced-motion: reduce) {
    .jogether .spinner { animation: none; }
}
""";
