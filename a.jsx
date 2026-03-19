import React, { useState } from 'react';
import { 
  collection, 
  query, 
  where, 
  getDocs, 
  doc, 
  updateDoc 
} from 'firebase/firestore';
import { db } from './firebase';

// Theme Colors (matching SwiftUI AppColors)
const theme = {
  appBackground: 'linear-gradient(135deg, #F0F4F8 0%, #E8EEF4 100%)',
  primaryPurple: '#8B5CF6',
  textPrimary: '#1F2937',
  textSecondary: '#6B7280',
  surfaceLight: '#F9FAFB',
  cardBackground: 'rgba(255, 255, 255, 0.92)',
  cardBorder: 'rgba(255, 255, 255, 0.9)',
  success: '#10B981',
  error: '#DC2626',
  warning: '#F59E0B',
  info: '#3B82F6'
};

const isRealDate = (day, month, year) => {
  const parsed = new Date(year, month - 1, day);

  return (
    parsed.getFullYear() === year &&
    parsed.getMonth() === month - 1 &&
    parsed.getDate() === day
  );
};

const toDdMmYyyy = (value) => {
  if (!value) return '';

  const trimmed = value.trim();
  const isoMatch = trimmed.match(/^(\d{4})-(\d{2})-(\d{2})$/);
  if (isoMatch) {
    const year = Number(isoMatch[1]);
    const month = Number(isoMatch[2]);
    const day = Number(isoMatch[3]);

    if (!isRealDate(day, month, year)) return '';

    return `${String(day).padStart(2, '0')}/${String(month).padStart(2, '0')}/${year}`;
  }

  const vnMatch = trimmed.match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (vnMatch) {
    const day = Number(vnMatch[1]);
    const month = Number(vnMatch[2]);
    const year = Number(vnMatch[3]);

    if (!isRealDate(day, month, year)) return '';

    return `${String(day).padStart(2, '0')}/${String(month).padStart(2, '0')}/${year}`;
  }

  return '';
};

function App() {
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  
  const [checkInfo, setCheckInfo] = useState({ hoTen: '', maSV: '' });
  
  const [memberId, setMemberId] = useState('');
  const [ngaySinhInput, setNgaySinhInput] = useState('');
  const [userData, setUserData] = useState({
    hoTen: '',
    maSV: '',
    ngaySinh: '',
    soDienThoai: '',
    email: '',
    trangThai: '_update_'
  });

  const handleCheckMember = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      const q = query(
        collection(db, "member"),
        where("hoTen", "==", checkInfo.hoTen),
        where("maSV", "==", checkInfo.maSV)
      );

      const querySnapshot = await getDocs(q);
      
      if (!querySnapshot.empty) {
        const docData = querySnapshot.docs[0];
        setMemberId(docData.id);
        const data = docData.data();
        const normalizedNgaySinh = toDdMmYyyy(data.ngaySinh || '');

        setNgaySinhInput(normalizedNgaySinh);
        setUserData((prev) => ({
          ...prev,
          hoTen: data.hoTen || checkInfo.hoTen,
          maSV: data.maSV || checkInfo.maSV,
          ngaySinh: normalizedNgaySinh,
          soDienThoai: data.soDienThoai || '',
          email: data.email || '',
        }));
        setStep(2);
      } else {
        alert("Không tìm thấy sinh viên này trong hệ thống!");
      }
    } catch (error) {
      console.error("Lỗi: ", error);
      alert("Có lỗi xảy ra khi kiểm tra thông tin!");
    } finally {
      setLoading(false);
    }
  };

  const handleSaveData = async (e) => {
    e.preventDefault();
    setLoading(true);
    try {
      if (!userData.ngaySinh || userData.ngaySinh.trim() === '') {
        alert('Ngày sinh không được để trống!');
        setLoading(false);
        return;
      }

      const formattedNgaySinh = toDdMmYyyy(userData.ngaySinh);
      if (!formattedNgaySinh) {
        setNgaySinhInput('');
        setUserData((prev) => ({ ...prev, ngaySinh: '' }));
        alert('Ngày sinh không hợp lệ. Vui lòng nhập đúng định dạng dd/mm/yyyy.');
        setLoading(false);
        return;
      }

      if (!userData.soDienThoai || userData.soDienThoai.trim() === '') {
        alert('Số điện thoại không được để trống!');
        setLoading(false);
        return;
      }

      const phonePattern = /^0\d{9}$/;
      if (!phonePattern.test(userData.soDienThoai.trim())) {
        alert('Số điện thoại phải bắt đầu từ 0 và có đúng 10 số!');
        setLoading(false);
        return;
      }

      if (!userData.email || userData.email.trim() === '') {
        alert('Email không được để trống!');
        setLoading(false);
        return;
      }

      const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailPattern.test(userData.email.trim())) {
        alert('Email không đúng định dạng!');
        setLoading(false);
        return;
      }

      const memberRef = doc(db, "member", memberId);
      await updateDoc(memberRef, {
        ...userData,
        ngaySinh: formattedNgaySinh,
        soDienThoai: userData.soDienThoai.trim(),
        email: userData.email.trim(),
      });
      
      setUserData((prev) => ({
        ...prev,
        ngaySinh: formattedNgaySinh,
        soDienThoai: userData.soDienThoai.trim(),
        email: userData.email.trim(),
      }));
      
      setStep(3);
    } catch (error) {
      console.error("Lỗi: ", error);
      alert("Lỗi khi cập nhật dữ liệu.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{textAlign:'center', padding: '20px', maxWidth: '400px', margin: '0 auto', fontFamily: 'sans-serif' }}>
      <h2 style={{ color: '#e63946', marginBottom: '20px'}}>Hệ Thống Ban Công Nghệ</h2>

      {step === 1 && (
        <form onSubmit={handleCheckMember}>
          <h3 ststyles.container}>
      <div style={styles.content}>
        {/* Header Card */}
        <div style={styles.headerCard}>
          <div style={styles.headerIconContainer}>
            <span style={styles.headerIcon}>🎓</span>
          </div>
          <h2 style={styles.headerTitle}>Hệ Thống Ban Công Nghệ</h2>
          <p style={styles.headerSubtitle}>
            {step === 1 && "Xác thực thông tin sinh viên để tiếp tục"}
            {step === 2 && "Cập nhật thông tin cá nhân của bạn"}
            {step === 3 && "Thông tin đã được lưu thành công"}
          </p>
          <div style={styles.statusChip}>
            <span style={styles.chipIcon}>🔒</span>
            <span style={styles.chipText}>Secure System</span>
          </div>
        </div>

        {/* Step 1: Authentication Form */}
        {step === 1 && (
          <div style={styles.formCard}>
            <h3 style={styles.formTitle}>Xác thực thông tin</h3>
            <form onSubmit={handleCheckMember}>
              <div style={styles.inputGroup}>
                <label style={styles.label}>
                  <span style={styles.labelIcon}>👤</span>
                  Họ và Tên
                </label>
                <input 
                  style={styles.input}
                  type="text" 
                  required 
                  placeholder="Nhập họ và tên"
                  onChange={(e) => setCheckInfo({...checkInfo, hoTen: e.target.value})} 
                />
              </div>
              <div style={styles.inputGroup}>
                <label style={styles.label}>
                  <span style={styles.labelIcon}>🎫</span>
                  Mã Sinh Viên
                </label>
                <input 
                  style={styles.input}
                  type="text" 
                  required 
                  placeholder="Nhập mã sinh viên"
                  onChange={(e) => setCheckInfo({...checkInfo, maSV: e.target.value})} 
                />
              </div>
              <button style={styles.primaryButton} type="submit" disabled={loading}>
                {loading ? (
                  <>
                    <span style={styles.spinner}></span>
                    Đang kiểm tra...
                  </>
                ) : (
                  <>
                    <span>Tiếp theo</span>
                    <span style={styles.buttonArrow}>→</span>
                  </>
                )}
              </button>
            </form>
          </div>
        )}

        {/* Step 2: Edit Information Form */}
        {step === 2 && (
          <div style={styles.formCard}>
            <h3 style={styles.formTitle}>Chỉnh sửa thông tin</h3>
            <form onSubmit={handleSaveData}>
              <div style={styles.inputGroup}>
                <label style={styles.label}>
                  <span style={styles.labelIcon}>📅</span>
                  Ngày sinh
                  <span style={styles.required}>*</span>
                </label>
                <input 
                  style={styles.input}
                  type="text"
                  inputMode="numeric"
                  maxLength={10}
                  placeholder="dd/mm/yyyy"
                  value={ngaySinhInput}
                  onChange={(e) => {
                    const inputValue = e.target.value;
                    setNgaySinhInput(inputValue);
                    setUserData((prev) => ({ ...prev, ngaySinh: inputValue }));
                  }}
                  onBlur={() => {
                    const normalized = toDdMmYyyy(ngaySinhInput);
                    if (!normalized) {
                      setNgaySinhInput('');
                      setUserData((prev) => ({ ...prev, ngaySinh: '' }));
                      return;
                    }
                    setNgaySinhInput(normalized);
                    setUserData((prev) => ({ ...prev, ngaySinh: normalized }));
                  }}
                  required
                />
              </div>
              <div style={styles.inputGroup}>
                <label style={styles.label}>
                  <span style={styles.labelIcon}>📱</span>
                  Số điện thoại
                  <span style={styles.required}>*</span>
                </label>
                <input 
                  style={styles.input}
                  type="tel"
                  inputMode="numeric"
                  maxLength={10}
                  placeholder="0xxxxxxxxx"
                  value={userData.soDienThoai}
                  onChange={(e) => {
                    const value = e.target.value.replace(/\D/g, '');
                    setUserData({...userData, soDienThoai: value});
                  }}
                  required
                />
              </div>
              <div style={styles.inputGroup}>
                <label style={styles.label}>
                  <span style={styles.labelIcon}>✉️</span>
                  Email
                  <span style={styles.required}>*</span>
                </label>
                <input 
                  style={styles.input}
                  type="email"
                  placeholder="example@domain.com"
                  value={userData.email}
                  onChange={(e) => setUserData({...userData, email: e.target.value})} 
                  required
        s matching SwiftUI theme
const styles = {
  container: {
    minHeight: '100vh',
    background: theme.appBackground,
    padding: '20px',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
  },
  content: {
    maxWidth: '480px',
    margin: '0 auto',
  },
  headerCard: {
    background: theme.cardBackground,
    borderRadius: '24px',
    padding: '24px',
    marginBottom: '16px',
    boxShadow: `0 5px 20px ${theme.primaryPurple}22`,
    border: `1px solid ${theme.cardBorder}`,
    textAlign: 'center',
  },
  headerIconContainer: {
    width: '56px',
    height: '56px',
    margin: '0 auto 16px',
    background: `${theme.primaryPurple}22`,
    borderRadius: '16px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerIcon: {
    fontSize: '28px',
  },
  headerTitle: {
    fontSize: '22px',
    fontWeight: '700',
    color: theme.textPrimary,
    margin: '0 0 8px 0',
  },
  headerSubtitle: {
    fontSize: '13px',
    color: theme.textSecondary,
    lineHeight: '1.5',
    margin: '0 0 16px 0',
  },
  statusChip: {
    display: 'inline-flex',
    alignItems: 'center',
    gap: '6px',
    background: `${theme.primaryPurple}22`,
    color: theme.primaryPurple,
    padding: '6px 12px',
    borderRadius: '999px',
    fontSize: '11px',
    fontWeight: '700',
  },
  chipIcon: {
    fontSize: '12px',
  },
  chipText: {
    textTransform: 'uppercase',
    letterSpacing: '0.5px',
  },
  formCard: {
    background: theme.cardBackground,
    borderRadius: '24px',
    padding: '24px',
    boxShadow: `0 5px 20px ${theme.primaryPurple}22`,
    border: `1px solid ${theme.cardBorder}`,
  },
  formTitle: {
    fontSize: '18px',
    fontWeight: '700',
    color: theme.textPrimary,
    margin: '0 0 20px 0',
  },
  inputGroup: {
    marginBottom: '16px',
  },
  label: {
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    fontSize: '14px',
    fontWeight: '600',
    color: theme.textPrimary,
    marginBottom: '8px',
  },
  labelIcon: {
    fontSize: '16px',
  },
  required: {
    color: theme.error,
    marginLeft: '4px',
  },
  input: {
    width: '100%',
    padding: '12px 16px',
    fontSize: '15px',
    border: `2px solid ${theme.surfaceLight}`,
    borderRadius: '16px',
    background: 'white',
    color: theme.textPrimary,
    transition: 'all 0.2s ease',
    outline: 'none',
    boxSizing: 'border-box',
  },
  primaryButton: {
    width: '100%',
    padding: '14px 20px',
    fontSize: '15px',
    fontWeight: '600',
    color: 'white',
    background: theme.primaryPurple,
    border: 'none',
    borderRadius: '16px',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '8px',
    transition: 'all 0.2s ease',
    marginTop: '8px',
    boxShadow: `0 4px 12px ${theme.primaryPurple}40`,
  },
  secondaryButton: {
    width: '100%',
    padding: '14px 20px',
    fontSize: '15px',
    fontWeight: '600',
    color: theme.textPrimary,
    background: theme.surfaceLight,
    border: 'none',
    borderRadius: '16px',
    cursor: 'pointer',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '8px',
    transition: 'all 0.2s ease',
    marginTop: '8px',
  },
  buttonArrow: {
    fontSize: '18px',
    fontWeight: '700',
  },
  spinner: {
    width: '16px',
    height: '16px',
    border: '2px solid rgba(255,255,255,0.3)',
    borderTop: '2px solid white',
    borderRadius: '50%',
    animation: 'spin 0.8s linear infinite',
    display: 'inline-block',
  },
  successHeader: {
    textAlign: 'center',
    marginBottom: '24px',
  },
  successIcon: {
    width: '64px',
    height: '64px',
    margin: '0 auto 16px',
    background: `${theme.success}22`,
    borderRadius: '50%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: '32px',
    color: theme.success,
    fontWeight: '700',
  },
  successTitle: {
    fontSize: '20px',
    fontWeight: '700',
    color: theme.success,
    margin: '0 0 8px 0',
  },
  successSubtitle: {
    fontSize: '13px',
    color: theme.textSecondary,
    margin: '0',
  },
  infoCard: {
    background: theme.surfaceLight,
    borderRadius: '16px',
    padding: '16px',
    marginBottom: '16px',
  },
  infoRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '12px 0',
    borderBottom: `1px solid ${theme.cardBorder}`,
  },
  infoLabel: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    fontSize: '14px',
    fontWeight: '600',
    color: theme.textSecondary,
  },
  infoIcon: {
    fontSize: '16px',
  },
  infoValue: {
    fontSize: '14px',
    fontWeight: '600',
    color: theme.textPrimary,
    textAlign: 'right',
  },
};

// Add CSS animation for spinner
const styleSheet = document.createElement("style");
styleSheet.textContent = `
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  
  input:focus {
    border-color: ${theme.primaryPurple} !important;
    box-shadow: 0 0 0 3px ${theme.primaryPurple}22 !important;
  }
  
  button:hover:not(:disabled) {
    transform: translateY(-2px);
    box-shadow: 0 6px 16px ${theme.primaryPurple}50;
  }
  
  button:active:not(:disabled) {
    transform: translateY(0);
  }
  
  button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }
`;
document.head.appendChild(styleSheet)             <InfoRow icon="📱" label="Số điện thoại" value={userData.soDienThoai} />
              <InfoRow icon="✉️" label="Email" value={userData.email} />
            </div>
            
            <button 
              style={styles.secondaryButton} 
              onClick={() => {
                setStep(1);
                setCheckInfo({ hoTen: '', maSV: '' });
                setNgaySinhInput('');
                setUserData({
                  hoTen: '',
                  maSV: '',
                  ngaySinh: '',
                  soDienThoai: '',
                  email: '',
                  trangThai: '_update_'
                });
                setMemberId('');
              }}
            >
              <span>Hoàn thành</span>
              <span style={styles.buttonArrow}>→</span>
            </button>
          </div>
        )}
      </div>
    </div>
  );
}

// Info Row Component for Step 3
const InfoRow = ({ icon, label, value }) => (
  <div style={styles.infoRow}>
    <div style={styles.infoLabel}>
      <span style={styles.infoIcon}>{icon}</span>
      <span>{label}</span>
    </div>
    <div style={styles.infoValue}>{value}</div>
  </div>
); padding: '8px',
  marginTop: '5px',
  borderRadius: '4px',
  border: '1px solid #ccc'
};

const buttonStyle = {
  width: '100%',
  padding: '10px',
  backgroundColor: '#e63946',
  color: 'white',
  border: 'none',
  borderRadius: '4px',
  cursor: 'pointer',
  marginTop: '10px'
};

const infoBoxStyle = {
  backgroundColor: '#f8f9fa',
  padding: '20px',
  borderRadius: '8px',
  marginBottom: '20px',
  border: '1px solid #dee2e6'
};

const infoRowStyle = {
  marginBottom: '12px',
  fontSize: '15px',
  lineHeight: '1.6'
};

export default App;