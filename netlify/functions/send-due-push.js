/**
 * Netlify Scheduled Function: send-due-push
 *
 * Runs on a cron schedule (set in netlify.toml).
 * Queries Supabase for tasks whose next_due_date has passed,
 * then sends a Web Push notification to the linked subscription.
 *
 * Required environment variables (set in Netlify dashboard → Site settings → Env vars):
 *   SUPABASE_URL          — your project URL
 *   SUPABASE_SERVICE_KEY  — service role key (NOT anon — needs to read all rows)
 *   VAPID_PUBLIC_KEY      — base64url VAPID public key
 *   VAPID_PRIVATE_KEY     — base64url VAPID private key
 *   VAPID_SUBJECT         — must be a mailto: address, e.g. mailto:you@yourapp.com
 *
 * netlify.toml schedule example:
 *   [functions."send-due-push"]
 *     schedule = "0 9 * * *"   # fires at 9:00 AM UTC daily
 */

const webpush = require('web-push');
const { createClient } = require('@supabase/supabase-js');

exports.handler = async () => {
    // ── Validate env vars ────────────────────────────────────────────────────
    const {
        SUPABASE_URL,
        SUPABASE_SERVICE_KEY,
        VAPID_PUBLIC_KEY,
        VAPID_PRIVATE_KEY,
        VAPID_SUBJECT,
    } = process.env;

    if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
        console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_KEY');
        return { statusCode: 500, body: 'Missing Supabase env vars' };
    }
    if (!VAPID_PUBLIC_KEY || !VAPID_PRIVATE_KEY || !VAPID_SUBJECT) {
        console.error('Missing VAPID env vars');
        return { statusCode: 500, body: 'Missing VAPID env vars' };
    }

    webpush.setVapidDetails(VAPID_SUBJECT, VAPID_PUBLIC_KEY, VAPID_PRIVATE_KEY);

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // ── Fetch due tasks joined with their push subscription ──────────────────
    const now = new Date().toISOString();
    const { data: dueTasks, error } = await supabase
        .from('push_tasks')
        .select('task_id, task_name, next_due_date, push_subscriptions(*)')
        .lte('next_due_date', now);

    if (error) {
        console.error('Supabase query error:', error);
        return { statusCode: 500, body: 'Supabase error' };
    }

    if (!dueTasks || dueTasks.length === 0) {
        console.log('No due tasks at', now);
        return { statusCode: 200, body: 'No due tasks' };
    }

    console.log(`Sending ${dueTasks.length} push notification(s)`);

    // ── Send a push for each due task ────────────────────────────────────────
    const results = await Promise.allSettled(
        dueTasks.map(async (task) => {
            const sub = task.push_subscriptions;
            if (!sub || !sub.subscription) {
                console.warn(`No subscription linked for task: ${task.task_id}`);
                return;
            }

            const payload = JSON.stringify({
                title: 'CleanTrack Reminder',
                body: `Time to clean: ${task.task_name}`,
                icon: '/icons/Icon-192.png',
                badge: '/icons/Icon-192.png',
                tag: task.task_id, // deduplicates notifications on the device
            });

            await webpush.sendNotification(
                JSON.parse(sub.subscription),
                payload
            );
            console.log(`Sent push for task: ${task.task_name}`);
        })
    );

    // Log any individual send failures (expired subscriptions, etc.)
    results.forEach((result, i) => {
        if (result.status === 'rejected') {
            console.error(`Push failed for task index ${i}:`, result.reason);
        }
    });

    return { statusCode: 200, body: `Sent ${dueTasks.length} notification(s)` };
};
