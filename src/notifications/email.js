const { EmailClient } = require('@azure/communication-email');

const {
    CONNECTION_EMAIL_CONNECTIONSTRING: CONNECTION_STRING,
    CONNECTION_EMAIL_SENDERADDRESS: SENDER_ADDRESS,
    NOTIFICATION_EMAIL_TO: RECIPIENT,
} = process.env;

let client;

function isEnabled() {
    return Boolean(CONNECTION_STRING && SENDER_ADDRESS && RECIPIENT);
}

function describe(action, item) {
    const name = item && item.name ? `"${item.name}"` : 'an item';
    switch (action) {
        case 'added':
            return `Todo added: ${name}`;
        case 'deleted':
            return `Todo deleted: ${name}`;
        default:
            return `Todo updated: ${name} (${
                item && item.completed ? 'completed' : 'not completed'
            })`;
    }
}

async function notify(action, item) {
    if (!isEnabled()) return;

    const subject = describe(action, item);
    try {
        client = client || new EmailClient(CONNECTION_STRING);
        const poller = await client.beginSend({
            senderAddress: SENDER_ADDRESS,
            recipients: { to: [{ address: RECIPIENT }] },
            content: {
                subject,
                plainText: `${subject}\n\nItem ID: ${
                    item ? item.id : 'unknown'
                }\nTime: ${new Date().toISOString()}`,
            },
        });
        const result = await poller.pollUntilDone();
        console.log(
            `Email notification sent: action=${action} operationId=${result.id} status=${result.status}`,
        );
    } catch (err) {
        console.error(
            `Email notification failed: action=${action} error=${err.message}`,
        );
    }
}

module.exports = { notify, isEnabled };
