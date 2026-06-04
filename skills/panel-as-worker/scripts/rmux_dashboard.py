#!/usr/bin/env python3
import argparse
import html
import http.server
import json
import subprocess
import urllib.parse
from datetime import datetime


def run_rmux(args):
    try:
        return subprocess.check_output(["rmux", *args], text=True, stderr=subprocess.DEVNULL)
    except (FileNotFoundError, subprocess.CalledProcessError, PermissionError):
        return ""


def list_sessions():
    out = run_rmux(["list-sessions", "-F", "#{session_name}\t#{session_windows}\t#{session_attached}"])
    sessions = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) != 3:
            continue
        sessions.append({"name": parts[0], "windows": parts[1], "attached": parts[2]})
    return sessions


def list_panes(session):
    out = run_rmux(
        [
            "list-panes",
            "-t",
            session,
            "-F",
            "#{pane_id}\t#{pane_index}\t#{pane_current_command}\t#{pane_title}\t#{pane_current_path}",
        ]
    )
    panes = []
    for line in out.splitlines():
        parts = line.split("\t")
        if len(parts) != 5:
            continue
        panes.append(
            {
                "id": parts[0],
                "index": parts[1],
                "command": parts[2],
                "title": parts[3],
                "path": parts[4],
            }
        )
    return panes


def capture_pane(target, lines):
    return run_rmux(["capture-pane", "-p", "-t", target, "-S", f"-{lines}"])


def page(title, body, refresh=None):
    refresh_tag = f'<meta http-equiv="refresh" content="{refresh}">' if refresh else ""
    return f"""<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  {refresh_tag}
  <title>{html.escape(title)}</title>
  <style>
    :root {{
      color-scheme: dark;
      --bg: #111315;
      --panel: #1a1d20;
      --line: #2f353b;
      --text: #e6e8ea;
      --muted: #9aa3ad;
      --accent: #78b7ff;
    }}
    body {{
      margin: 0;
      font: 14px/1.45 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: var(--bg);
      color: var(--text);
    }}
    header {{
      position: sticky;
      top: 0;
      z-index: 1;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      padding: 12px 18px;
      border-bottom: 1px solid var(--line);
      background: #15181b;
    }}
    h1 {{ font-size: 16px; margin: 0; }}
    main {{ padding: 16px 18px; }}
    a {{ color: var(--accent); text-decoration: none; }}
    a:hover {{ text-decoration: underline; }}
    .muted {{ color: var(--muted); }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(360px, 1fr));
      gap: 12px;
    }}
    .card {{
      border: 1px solid var(--line);
      border-radius: 8px;
      background: var(--panel);
      overflow: hidden;
    }}
    .card h2 {{
      font-size: 14px;
      margin: 0;
      padding: 10px 12px;
      border-bottom: 1px solid var(--line);
      display: flex;
      justify-content: space-between;
      gap: 12px;
    }}
    .body {{ padding: 10px 12px; }}
    .pane {{
      border-top: 1px solid var(--line);
      padding: 10px 12px;
    }}
    .pane:first-child {{ border-top: 0; }}
    pre {{
      white-space: pre-wrap;
      word-break: break-word;
      margin: 0;
      padding: 12px;
      border: 1px solid var(--line);
      border-radius: 8px;
      background: #080a0c;
      color: #d7dde4;
      font: 12px/1.4 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
    }}
    .row {{
      display: flex;
      flex-wrap: wrap;
      gap: 8px 12px;
      align-items: baseline;
    }}
    .badge {{
      display: inline-block;
      padding: 1px 6px;
      border: 1px solid var(--line);
      border-radius: 999px;
      color: var(--muted);
      font-size: 12px;
    }}
  </style>
</head>
<body>
  <header>
    <h1>{html.escape(title)}</h1>
    <div class="muted">{html.escape(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))}</div>
  </header>
  <main>{body}</main>
</body>
</html>
"""


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        qs = urllib.parse.parse_qs(parsed.query)
        refresh = int(qs.get("refresh", ["5"])[0])
        lines = int(qs.get("lines", ["80"])[0])

        if parsed.path == "/api/sessions":
            data = []
            for session in list_sessions():
                item = dict(session)
                item["panes"] = list_panes(session["name"])
                data.append(item)
            self.send_json(data)
            return

        if parsed.path == "/pane":
            target = qs.get("target", [""])[0]
            if not target:
                self.send_error(400, "missing target")
                return
            text = capture_pane(target, lines)
            body = f"""
              <p><a href="/">Back</a> <span class="muted">target={html.escape(target)} lines={lines}</span></p>
              <pre>{html.escape(text)}</pre>
            """
            self.send_html(page(f"rmux pane {target}", body, refresh=refresh))
            return

        if parsed.path != "/":
            self.send_error(404)
            return

        cards = []
        for session in list_sessions():
            panes_html = []
            for pane in list_panes(session["name"]):
                target = f'{session["name"]}:0.{pane["index"]}'
                href = f"/pane?target={urllib.parse.quote(target)}&lines={lines}&refresh={refresh}"
                preview = capture_pane(target, min(lines, 25)).splitlines()[-25:]
                panes_html.append(
                    f"""
                    <div class="pane">
                      <div class="row">
                        <a href="{href}">{html.escape(target)}</a>
                        <span class="badge">{html.escape(pane["command"])}</span>
                        <span class="muted">{html.escape(pane["title"])}</span>
                      </div>
                      <div class="muted">{html.escape(pane["path"])}</div>
                      <pre>{html.escape(chr(10).join(preview))}</pre>
                    </div>
                    """
                )
            cards.append(
                f"""
                <section class="card">
                  <h2>
                    <span>{html.escape(session["name"])}</span>
                    <span class="badge">attached={html.escape(session["attached"])}</span>
                  </h2>
                  <div class="body muted">windows={html.escape(session["windows"])}</div>
                  {''.join(panes_html)}
                </section>
                """
            )
        empty = """
          <p>No rmux sessions visible.</p>
          <p class="muted">If sessions exist, run this dashboard from the same WSL user outside Codex sandbox.</p>
        """
        body = f"""
          <p class="muted">Read-only monitor. Auto-refresh every {refresh}s. Use <code>?refresh=2&lines=120</code> to tune.</p>
          <div class="grid">{''.join(cards) if cards else empty}</div>
        """
        self.send_html(page("rmux agent dashboard", body, refresh=refresh))

    def log_message(self, fmt, *args):
        return

    def send_html(self, text):
        data = text.encode("utf-8")
        self.send_response(200)
        self.send_header("content-type", "text/html; charset=utf-8")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, obj):
        data = json.dumps(obj, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(200)
        self.send_header("content-type", "application/json; charset=utf-8")
        self.send_header("content-length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument("--open", action="store_true", help="Print a Windows PowerShell command for opening the dashboard.")
    args = parser.parse_args()
    server = http.server.ThreadingHTTPServer((args.host, args.port), Handler)
    url_host = "127.0.0.1" if args.host in {"0.0.0.0", "::"} else args.host
    url = f"http://{url_host}:{args.port}"
    print(f"[INFO] rmux dashboard: {url}", flush=True)
    if args.open:
        print(f"[INFO] Windows: powershell.exe -NoProfile -Command Start-Process {url}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
