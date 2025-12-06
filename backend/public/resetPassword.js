const token = window.location.pathname.split('/').pop();
const form = document.getElementById('resetForm');
const alertBox = document.getElementById('alert');
const btn = document.getElementById('submitBtn');

function showAlert(msg, type) {
  alertBox.textContent = msg;
  alertBox.className = "alert " + type;
  alertBox.style.display = "block";
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const p1 = document.getElementById("password").value;
  const p2 = document.getElementById("confirmPassword").value;

  if (p1 !== p2) return showAlert("Passwords do not match", "error");
  if (p1.length < 8) return showAlert("Password too short", "error");

  btn.disabled = true;

  const res = await fetch(`/api/auth/reset-password/${token}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ password: p1, confirmPassword: p2 }),
  });

  const data = await res.json();
  if (data.success) {
    showAlert("Password changed successfully! Redirecting...", "success");
    setTimeout(() => (location.href = "/login"), 2000);
  } else {
    showAlert(data.message, "error");
    btn.disabled = false;
  }
});
