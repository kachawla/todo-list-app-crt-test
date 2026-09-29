const mockBeginSend = jest.fn();

jest.mock('@azure/communication-email', () => ({
    EmailClient: jest.fn().mockImplementation(() => ({
        beginSend: mockBeginSend,
    })),
}));

const ENV_KEYS = [
    'CONNECTION_EMAIL_CONNECTIONSTRING',
    'CONNECTION_EMAIL_SENDERADDRESS',
    'NOTIFICATION_EMAIL_TO',
];

function loadWithEnv(env) {
    jest.resetModules();
    for (const key of ENV_KEYS) delete process.env[key];
    Object.assign(process.env, env);
    return require('../../src/notifications/email');
}

afterEach(() => {
    mockBeginSend.mockReset();
    for (const key of ENV_KEYS) delete process.env[key];
});

test('it does nothing when email is not configured', async () => {
    const email = loadWithEnv({});

    expect(email.isEnabled()).toBe(false);
    await email.notify('added', { id: '1', name: 'Milk' });
    expect(mockBeginSend).not.toHaveBeenCalled();
});

test('it sends an email for each change when configured', async () => {
    const email = loadWithEnv({
        CONNECTION_EMAIL_CONNECTIONSTRING: 'endpoint=https://x/;accesskey=a',
        CONNECTION_EMAIL_SENDERADDRESS: 'DoNotReply@example.com',
        NOTIFICATION_EMAIL_TO: 'me@example.com',
    });
    mockBeginSend.mockResolvedValue({
        pollUntilDone: () => Promise.resolve({ id: 'op1', status: 'Succeeded' }),
    });
    jest.spyOn(console, 'log').mockImplementation(() => {});

    await email.notify('updated', { id: '1', name: 'Milk', completed: true });

    expect(mockBeginSend).toHaveBeenCalledTimes(1);
    const message = mockBeginSend.mock.calls[0][0];
    expect(message.senderAddress).toBe('DoNotReply@example.com');
    expect(message.recipients.to).toEqual([{ address: 'me@example.com' }]);
    expect(message.content.subject).toBe('Todo updated: "Milk" (completed)');
});

test('it logs and swallows send failures', async () => {
    const email = loadWithEnv({
        CONNECTION_EMAIL_CONNECTIONSTRING: 'endpoint=https://x/;accesskey=a',
        CONNECTION_EMAIL_SENDERADDRESS: 'DoNotReply@example.com',
        NOTIFICATION_EMAIL_TO: 'me@example.com',
    });
    mockBeginSend.mockRejectedValue(new Error('boom'));
    const error = jest.spyOn(console, 'error').mockImplementation(() => {});

    await expect(email.notify('deleted', { id: '1' })).resolves.toBeUndefined();
    expect(error).toHaveBeenCalledWith(expect.stringContaining('boom'));
});
