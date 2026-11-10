import { spawn } from 'child_process';
import { writeFileSync, mkdirSync } from 'fs';
import { resolve } from 'path';

const ARTIFACT_DIR = 'C:\\Users\\walid\\.gemini\\antigravity\\brain\\d9820364-c166-41d2-a9f3-8981eebd34df';
mkdirSync('screenshots', { recursive: true });
mkdirSync(ARTIFACT_DIR, { recursive: true });

const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';

async function main() {
  const chrome = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--disable-gpu',
    '--no-sandbox',
    'about:blank'
  ]);

  await new Promise(r => setTimeout(r, 2000));

  try {
    const listRes = await fetch('http://localhost:9222/json');
    const tabs = await listRes.json();
    const tab = tabs.find(t => t.type === 'page') || tabs[0];
    if (!tab || !tab.webSocketDebuggerUrl) throw new Error('No tab found');

    const ws = new WebSocket(tab.webSocketDebuggerUrl);
    let msgId = 1;
    const pending = new Map();

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      if (data.id && pending.has(data.id)) {
        const { resolve, reject } = pending.get(data.id);
        pending.delete(data.id);
        if (data.error) reject(data.error);
        else resolve(data.result);
      }
    };

    await new Promise(r => ws.onopen = r);

    function send(method, params = {}) {
      return new Promise((resolve, reject) => {
        const id = msgId++;
        pending.set(id, { resolve, reject });
        ws.send(JSON.stringify({ id, method, params }));
      });
    }

    await send('Page.enable');
    await send('Emulation.setDeviceMetricsOverride', {
      width: 412,
      height: 915,
      deviceScaleFactor: 2.5,
      mobile: true,
      fitWindow: false,
    });

    async function snap(name, waitMs = 3000) {
      await new Promise(res => setTimeout(res, waitMs));
      const { data } = await send('Page.captureScreenshot', { format: 'png' });
      const buffer = Buffer.from(data, 'base64');
      writeFileSync(resolve('screenshots', `${name}.png`), buffer);
      writeFileSync(resolve(ARTIFACT_DIR, `${name}.png`), buffer);
      console.log(`Saved ${name}.png (${buffer.length} bytes)`);
    }

    // 1. Login Screen
    await send('Page.navigate', { url: 'http://localhost:8080/#/login' });
    await snap('01_login_screen', 3500);

    // 2. Student Dashboard
    await send('Page.navigate', { url: 'http://localhost:8080/#/student' });
    await snap('02_student_dashboard', 3000);

    // 3. Teacher Dashboard
    await send('Page.navigate', { url: 'http://localhost:8080/#/teacher' });
    await snap('03_teacher_dashboard', 3000);

    // 4. Manager Dashboard
    await send('Page.navigate', { url: 'http://localhost:8080/#/manager' });
    await snap('04_manager_dashboard', 3000);

    // 5. Parent Dashboard
    await send('Page.navigate', { url: 'http://localhost:8080/#/parent' });
    await snap('05_parent_dashboard', 3000);

    // 6. Super Admin (Owner) Dashboard
    await send('Page.navigate', { url: 'http://localhost:8080/#/owner' });
    await snap('06_owner_superadmin', 3000);

    // 7. Library & Ministerial
    await send('Page.navigate', { url: 'http://localhost:8080/#/library' });
    await snap('07_library_ministerial', 3000);

    // 8. Subscriptions & Mastercard
    await send('Page.navigate', { url: 'http://localhost:8080/#/subscription' });
    await snap('08_subscription_mastercard', 3000);

    // 9. Settings
    await send('Page.navigate', { url: 'http://localhost:8080/#/settings' });
    await snap('09_settings_security', 3000);

    ws.close();
  } finally {
    chrome.kill();
  }
}

main().catch(console.error);
