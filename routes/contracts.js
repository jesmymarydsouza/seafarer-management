const express = require('express');
const router = express.Router();
const db = require('../database');

router.get('/', (req, res) => {
  const msg = req.query.msg || null;
  const detail = req.query.detail || null;
  db.query('SELECT * FROM active_contracts ORDER BY contract_id', (err, rows) => {
    db.query('SELECT seafarer_id, full_name FROM seafarers', (e2, seafarers) => {
      db.query('SELECT vessel_id, vessel_name FROM vessels', (e3, vessels) => {
        res.render('contracts', { contracts: rows || [], seafarers: seafarers || [], vessels: vessels || [], msg, detail });
      });
    });
  });
});

router.post('/add', (req, res) => {
  const { seafarer_id, vessel_id, start_date, end_date, monthly_salary } = req.body;
  db.query('INSERT INTO contracts (seafarer_id,vessel_id,start_date,end_date,monthly_salary) VALUES (?,?,?,?,?)',
    [seafarer_id, vessel_id, start_date, end_date, monthly_salary],
    (err) => {
      if (err) return res.redirect('/contracts?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/contracts?msg=added');
    });
});

router.post('/update', (req, res) => {
  const { contract_id, start_date, end_date, monthly_salary, contract_status } = req.body;
  db.query('UPDATE contracts SET start_date=?,end_date=?,monthly_salary=?,contract_status=? WHERE contract_id=?',
    [start_date, end_date, monthly_salary, contract_status, contract_id],
    (err) => {
      if (err) return res.redirect('/contracts?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/contracts?msg=updated');
    });
});

router.post('/delete', (req, res) => {
  db.query('DELETE FROM contracts WHERE contract_id=?', [req.body.contract_id],
    (err) => {
      if (err) return res.redirect('/contracts?msg=error&detail=' + encodeURIComponent(err.sqlMessage));
      res.redirect('/contracts?msg=deleted');
    });
});

module.exports = router;
