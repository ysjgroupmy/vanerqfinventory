// Zero-dependency static file server for local development.
//
// Serves this folder as-is, except for index.html: it reads .env and injects
// a small script that prefills the app's setup screen (window.localStorage)
// with your Supabase/Clerk keys, so you don't have to paste them in by hand
// each time you wipe browser storage. Production hosting (Netlify, S3, etc.)
// just serves the plain files and never sees .env — this is dev-only.

const http = require("http");
const fs = require("fs");
const path = require("path");

const ROOT = __dirname;
const PORT = process.env.PORT || 5173;

function loadEnv(file) {
  const out = {};
  if (!fs.existsSync(file)) return out;
  for (const line of fs.readFileSync(file, "utf8").split("\n")) {
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (!m || line.trim().startsWith("#")) continue;
    let val = m[2];
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    out[m[1]] = val;
  }
  return out;
}

const env = loadEnv(path.join(ROOT, ".env"));
const cfg = {
  supabaseUrl: env.SUPABASE_URL || "",
  supabaseAnonKey: env.SUPABASE_ANON_KEY || "",
  clerkKey: env.CLERK_PUBLISHABLE_KEY || "",
};
const cfgReady =
  cfg.supabaseUrl &&
  !cfg.supabaseUrl.includes("xxxxxxxx") &&
  cfg.supabaseAnonKey &&
  !cfg.supabaseAnonKey.includes("...") &&
  cfg.clerkKey &&
  !cfg.clerkKey.includes("...");

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".sql": "text/plain; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".ico": "image/x-icon",
};

function injectDevConfig(html) {
  const script = `<script>
    /* injected by dev-server.js from .env — dev only, never shipped */
    (function(){
      try{
        if(!localStorage.getItem("qf_cfg_v1")){
          localStorage.setItem("qf_cfg_v1", ${JSON.stringify(JSON.stringify(cfg))});
        }
      }catch(e){}
    })();
  </script>`;
  return html.replace("<head>", "<head>\n" + script);
}

const server = http.createServer((req, res) => {
  let urlPath = decodeURIComponent(req.url.split("?")[0]);
  if (urlPath === "/") urlPath = "/index.html";
  const filePath = path.join(ROOT, urlPath);

  if (!filePath.startsWith(ROOT)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404, { "Content-Type": "text/plain" });
      res.end("Not found: " + urlPath);
      return;
    }
    const ext = path.extname(filePath);
    const type = MIME[ext] || "application/octet-stream";

    if (filePath === path.join(ROOT, "index.html")) {
      res.writeHead(200, { "Content-Type": type });
      res.end(injectDevConfig(data.toString("utf8")));
    } else {
      res.writeHead(200, { "Content-Type": type });
      res.end(data);
    }
  });
});

server.listen(PORT, () => {
  console.log(`0428 Sauce Line — dev server running at http://localhost:${PORT}`);
  if (cfgReady) {
    console.log("Supabase/Clerk keys loaded from .env — the app will skip the setup screen.");
  } else {
    console.log("No (complete) .env found — fill in .env with your Supabase/Clerk keys,");
    console.log("or just paste them into the app's setup screen once it loads.");
  }
});
