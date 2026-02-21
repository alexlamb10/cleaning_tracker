/**
 * Netlify scheduled function: query Supabase for tasks due (next_due_date <= now),
 * fetch push_subscriptions, and send a Web Push notification per subscription.
 *
 * Required env vars (set in Netlify UI):
 *   SUPABASE_URL, SUPABASE_ANON_KEY (or SUPABASE_SERVICE_ROLE_KEY),
 *   VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY
 *
 * Schedule: set in netlify.toml, e.g. "0 9 * * *" (daily 9 AM UTC) or "0 */30 * * *" (every 30 min).
 */

const { createClient } = require('@supabase/supabase-js');
const webpush = require('web-push');

function getEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing env: ${name}`);
  return v;
}

async function run() {
  const now = new Date().toISOString();

  const supabaseUrl = getEnv('SUPABASE_URL');
  const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || getEnv('SUPABASE_ANON_KEY');
  const vapidPublicKey = getEnv('VAPID_PUBLIC_KEY');
  const vapidPrivateKey = getEnv('VAPID_PRIVATE_KEY');

  webpush.setVapidDetails(
    'mailto:support@cleantrack.app',
    vapidPublicKey,
    vapidPrivateKey
  );

  const supabase = createClient(supabaseUrl, supabaseKey);

  // Tasks whose next_due_date is in the past or now
  const { data: dueTasks, error: tasksError } = await supabase
    .from('push_tasks')
    .select('task_id, task_name, next_due_date')
    .lte('next_due_date', now)
    .not('next_due_date', 'is', null);

  if (tasksError) {
    console.error('Supabase push_tasks error:', tasksError);
    throw new Error(tasksError.message);
  }

  if (!dueTasks || dueTasks.length === 0) {
    console.log('No due tasks');
    return;
  }

  const { data: subs, error: subsError } = await supabase
    .from('push_subscriptions')
    .select('subscription')
    .order('updated_at', { ascending: false });

  if (subsError) {
    console.error('Supabase push_subscriptions error:', subsError);
    throw new Error(subsError.message);
  }

  if (!subs || subs.length === 0) {
    console.log('No push subscriptions');
    return;
  }

  let sent = 0;
  const payload = (task) => JSON.stringify({
    title: task.task_name,
    body: 'Time to clean!',
  });

  for (const task of dueTasks) {
    for (const row of subs) {
      let sub;
      try {
        sub = typeof row.subscription === 'string' ? JSON.parse(row.subscription) : row.subscription;
      } catch (e) {
        console.warn('Invalid subscription JSON:', e);
        continue;
      }
      try {
        await webpush.sendNotification(sub, payload(task));
        sent++;
      } catch (e) {
        if (e.statusCode === 410 || e.statusCode === 404) {
          console.warn('Subscription expired or invalid:', e.message);
        } else {
          console.warn('Web push failed:', e.message);
        }
      }
    }
  }

  console.log(`Sent ${sent} notification(s) for ${dueTasks.length} due task(s)`);
}

exports.handler = async function (event) {
  try {
    await run();
    return { statusCode: 200, body: '' };
  } catch (err) {
    console.error('send-due-push error:', err);
    return { statusCode: 500, body: JSON.stringify({ error: err.message }) };
  }
};
