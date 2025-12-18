'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { getAttendanceWithStatus, updateAttendanceStatus } from '@/lib/api';

interface AttendanceRecord {
  userId: string;
  userName: string;
  attend: number;
  alpha: number;
  permission: number;
  sick: number;
  total: number;
}

export default function LaporanAbsensiPage() {
  const router = useRouter();
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [attendanceRecords, setAttendanceRecords] = useState<AttendanceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [detailUserId, setDetailUserId] = useState<string | null>(null);
  const [detailData, setDetailData] = useState<any>(null);

  useEffect(() => {
    const isAuth = localStorage.getItem('isAuthenticated');
    if (!isAuth) {
      router.push('/login');
      return;
    }

    loadAttendanceData();
  }, [router, selectedMonth, selectedYear]);

  const loadAttendanceData = async () => {
    setLoading(true);
    try {
      const monthStr = `${selectedYear}-${(selectedMonth + 1).toString().padStart(2, '0')}`;
      const response = await getAttendanceWithStatus(monthStr);

      if (response.success) {
        const records: AttendanceRecord[] = response.records.map(user => {
          let attend = 0, alpha = 0, permission = 0, sick = 0;

          Object.values(user.days).forEach((day: any) => {
            switch (day.status) {
              case 'attend': attend++; break;
              case 'alpha': alpha++; break;
              case 'permission': permission++; break;
              case 'sick': sick++; break;
            }
          });

          const total = attend + alpha + permission + sick;

          return {
            userId: user.userId,
            userName: user.userName,
            attend,
            alpha,
            permission,
            sick,
            total
          };
        });

        setAttendanceRecords(records);
      }
    } catch (error) {
      console.error('Error loading attendance data:', error);
      alert('Failed to load attendance data');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (userId: string, date: string, newStatus: string) => {
    try {
      await updateAttendanceStatus(userId, date, newStatus as any);
      // Reload data after update
      await loadAttendanceData();
      // Reload detail if open
      if (detailUserId === userId) {
        await loadDetailData(userId);
      }
    } catch (error) {
      console.error('Error updating status:', error);
      alert('Failed to update status');
    }
  };

  const loadDetailData = async (userId: string) => {
    const monthStr = `${selectedYear}-${(selectedMonth + 1).toString().padStart(2, '0')}`;
    const response = await getAttendanceWithStatus(monthStr);

    if (response.success) {
      const user = response.records.find(r => r.userId === userId);
      if (user) {
        setDetailData({
          userName: user.userName,
          days: user.days,
          workingDays: response.workingDays
        });
      }
    }
  };

  const handleViewDetail = async (userId: string) => {
    setDetailUserId(userId);
    await loadDetailData(userId);
  };

  const getMonthName = (month: number) => {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  };

  const handlePreviousMonth = () => {
    if (selectedMonth === 0) {
      setSelectedMonth(11);
      setSelectedYear(selectedYear - 1);
    } else {
      setSelectedMonth(selectedMonth - 1);
    }
  };

  const handleNextMonth = () => {
    const currentDate = new Date();
    const currentMonth = currentDate.getMonth();
    const currentYear = currentDate.getFullYear();

    if (selectedYear === currentYear && selectedMonth === currentMonth) {
      return;
    }

    if (selectedMonth === 11) {
      setSelectedMonth(0);
      setSelectedYear(selectedYear + 1);
    } else {
      setSelectedMonth(selectedMonth + 1);
    }
  };

  const isCurrentMonth = () => {
    const currentDate = new Date();
    return selectedMonth === currentDate.getMonth() && selectedYear === currentDate.getFullYear();
  };

  const getAttendancePercentage = (attend: number, total: number) => {
    return total > 0 ? ((attend / total) * 100).toFixed(1) : '0';
  };

  const getStatusBadgeColor = (status: string) => {
    switch (status) {
      case 'attend': return 'bg-green-100 text-green-800';
      case 'alpha': return 'bg-red-100 text-red-800';
      case 'permission': return 'bg-yellow-100 text-yellow-800';
      case 'sick': return 'bg-blue-100 text-blue-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <DashboardLayout>
      <div className="p-8">
        <div className="bg-white rounded-xl shadow-lg p-6">
          <div className="flex justify-between items-center mb-6">
            <h1 className="text-2xl font-bold text-gray-900">Laporan Absensi</h1>

            <div className="flex items-center space-x-4">
              <button
                onClick={handlePreviousMonth}
                className="p-2 hover:bg-gray-100 rounded-lg transition"
              >
                <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
                </svg>
              </button>

              <div className="text-center min-w-[180px]">
                <p className="text-lg font-semibold text-gray-900">
                  {getMonthName(selectedMonth)} {selectedYear}
                </p>
                {isCurrentMonth() && (
                  <p className="text-xs text-blue-600">Current Month</p>
                )}
              </div>

              <button
                onClick={handleNextMonth}
                disabled={isCurrentMonth()}
                className={`p-2 rounded-lg transition ${isCurrentMonth()
                    ? 'opacity-50 cursor-not-allowed'
                    : 'hover:bg-gray-100'
                  }`}
              >
                <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          </div>

          {/* Attendance Table */}
          <div className="overflow-x-auto">
            {loading ? (
              <div className="text-center py-8 text-gray-500">Loading attendance data...</div>
            ) : (
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200">
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">No.</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Attend</th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Alpha</th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Permission</th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Sick</th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Total Days</th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Attendance %</th>
                    <th className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {attendanceRecords.map((record, index) => (
                    <tr key={record.userId} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{index + 1}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{record.userName}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-center">
                        <span className="px-2 py-1 text-sm font-semibold text-green-800 bg-green-100 rounded">
                          {record.attend}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-center">
                        <span className="px-2 py-1 text-sm font-semibold text-red-800 bg-red-100 rounded">
                          {record.alpha}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-center">
                        <span className="px-2 py-1 text-sm font-semibold text-yellow-800 bg-yellow-100 rounded">
                          {record.permission}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-center">
                        <span className="px-2 py-1 text-sm font-semibold text-blue-800 bg-blue-100 rounded">
                          {record.sick}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-center text-sm font-medium text-gray-900">
                        {record.total}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-center">
                        <span className="text-sm font-bold text-blue-600">
                          {getAttendancePercentage(record.attend, record.total)}%
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-center">
                        <button
                          onClick={() => handleViewDetail(record.userId)}
                          className="inline-flex items-center space-x-1 px-3 py-1 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition text-xs font-medium"
                        >
                          <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                          </svg>
                          <span>Edit Status</span>
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className="mt-4 text-sm text-gray-600">
            Showing {attendanceRecords.length} {attendanceRecords.length === 1 ? 'entry' : 'entries'}
          </div>
        </div>

        {/* Detail Modal */}
        {detailUserId && detailData && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" onClick={() => setDetailUserId(null)}>
            <div className="bg-white rounded-xl shadow-2xl p-6 w-full max-w-4xl max-h-[80vh] overflow-y-auto" onClick={(e) => e.stopPropagation()}>
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold text-gray-900">Edit Attendance Status - {detailData.userName}</h2>
                <button onClick={() => setDetailUserId(null)} className="text-gray-500 hover:text-gray-700">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div className="grid grid-cols-1 gap-2">
                {detailData.workingDays.map((date: string) => {
                  const dayData = detailData.days[date];
                  const dateObj = new Date(date);
                  const dayName = dateObj.toLocaleDateString('en-US', { weekday: 'short' });
                  const dayNum = dateObj.getDate();

                  return (
                    <div key={date} className="flex items-center justify-between p-3 border rounded-lg hover:bg-gray-50">
                      <div className="flex items-center space-x-4">
                        <div className="text-center">
                          <div className="text-xs text-gray-500">{dayName}</div>
                          <div className="text-lg font-bold">{dayNum}</div>
                        </div>
                        <div className="text-sm text-gray-600">{date}</div>
                      </div>

                      <select
                        value={dayData.status}
                        onChange={(e) => handleStatusChange(detailUserId, date, e.target.value)}
                        className={`px-3 py-1 rounded-lg text-sm font-semibold ${getStatusBadgeColor(dayData.status)} border-0 cursor-pointer`}
                      >
                        <option value="attend">Attend</option>
                        <option value="alpha">Alpha</option>
                        <option value="permission">Permission</option>
                        <option value="sick">Sick</option>
                      </select>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
