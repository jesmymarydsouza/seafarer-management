// Modal helpers
function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }

// Close modal on overlay click
document.querySelectorAll('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', e => { if (e.target === overlay) overlay.classList.remove('open'); });
});

// Table search filter
function filterTable(inputOrId, tableId) {
  const input = typeof inputOrId === 'string' ? document.getElementById(inputOrId) : inputOrId;
  const filter = input.value.toLowerCase();
  const rows = document.getElementById(tableId).querySelectorAll('tbody tr');
  rows.forEach(row => {
    row.style.display = row.textContent.toLowerCase().includes(filter) ? '' : 'none';
  });
}

// Seafarer edit modal
function openEdit(s) {
  document.getElementById('edit_id').value    = s.seafarer_id;
  document.getElementById('edit_name').value  = s.full_name;
  document.getElementById('edit_nat').value   = s.nationality;
  document.getElementById('edit_email').value = s.email || '';
  document.getElementById('edit_phone').value = s.phone || '';
  document.getElementById('edit_rank').value  = s.rank_id || '';
  document.getElementById('edit_status').value = s.status;
  openModal('editModal');
}

// Vessel edit modal
function openVesselEdit(v) {
  document.getElementById('v_id').value     = v.vessel_id;
  document.getElementById('v_name').value   = v.vessel_name;
  document.getElementById('v_type').value   = v.vessel_type;
  document.getElementById('v_flag').value   = v.flag_country;
  document.getElementById('v_gt').value     = v.gross_tonnage;
  document.getElementById('v_status').value = v.status;
  openModal('vesselModal');
}

// Contract edit modal
function openContractEdit(c) {
  document.getElementById('c_id').value     = c.contract_id;
  document.getElementById('c_start').value  = c.start_date ? c.start_date.split('T')[0] : '';
  document.getElementById('c_end').value    = c.end_date   ? c.end_date.split('T')[0]   : '';
  document.getElementById('c_salary').value = c.monthly_salary;
  document.getElementById('c_status').value = c.contract_status;
  openModal('contractModal');
}
