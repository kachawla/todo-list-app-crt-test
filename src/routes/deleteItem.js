const db = require('../persistence');
const { notify } = require('../notifications/email');

module.exports = async (req, res) => {
    const item = await db.getItem(req.params.id);
    await db.removeItem(req.params.id);
    res.sendStatus(200);
    notify('deleted', item || { id: req.params.id });
};
