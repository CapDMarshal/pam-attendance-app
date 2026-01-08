'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { getAllSlipGaji } from '@/lib/api';

interface SalarySlip {
  userId: string;
  userName: string;
  month: string;
  year: number;
  basicSalary: number;
  allowance: number;
  deductions: number;
  totalSalary: number;
  status: string;
  details: any[];
}

export default function SlipGajiPage() {
  const router = useRouter();
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [salarySlips, setSalarySlips] = useState<SalarySlip[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedSlip, setSelectedSlip] = useState<SalarySlip | null>(null);

  useEffect(() => {
    const isAuth = localStorage.getItem('isAuthenticated');
    if (!isAuth) {
      router.push('/login');
      return;
    }

    loadSalaryData();
  }, [router, selectedMonth, selectedYear]);

  const loadSalaryData = async () => {
    setLoading(true);
    try {
      // Month is 1-indexed in DB
      const response = await getAllSlipGaji(selectedMonth + 1, selectedYear);

      if (response.success) {
        const slips: SalarySlip[] = response.data.map(item => ({
          userId: item.userId,
          userName: item.userName,
          month: getMonthName(selectedMonth),
          year: item.year,
          basicSalary: item.basicSalary,
          allowance: item.allowance,
          deductions: item.deductions,
          totalSalary: item.totalSalary,
          status: item.status,
          details: item.details
        }));
        setSalarySlips(slips);
      }
    } catch (error) {
      console.error('Error loading salary data:', error);
      alert('Failed to load salary data');
    } finally {
      setLoading(false);
    }
  };

  const getMonthName = (month: number) => {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  };

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0
    }).format(amount);
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
      return; // Don't go beyond current month
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

  const handleViewDetail = (slip: SalarySlip) => {
    setSelectedSlip(slip);
  };

  return (
    <DashboardLayout>
      <div className="p-8">
        <div className="bg-white rounded-xl shadow-lg p-6">
          <div className="flex justify-between items-center mb-6">
            <h1 className="text-2xl font-bold text-gray-900">Slip Gaji</h1>

            {/* Month Selector */}
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

          {/* Salary Table */}
          <div className="overflow-x-auto">
            {loading ? (
              <div className="text-center py-8 text-gray-500">Loading salary data...</div>
            ) : (
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200">
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">No.</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Basic Salary</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Allowance</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Deductions</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total Salary</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Action</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {salarySlips.map((slip, index) => (
                    <tr key={slip.userId} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{index + 1}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{slip.userName}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">{formatCurrency(slip.basicSalary)}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-green-600">{formatCurrency(slip.allowance)}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-red-600">{formatCurrency(slip.deductions)}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-bold text-blue-600">{formatCurrency(slip.totalSalary)}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        <span className={`px-2 py-1 rounded-full text-xs font-semibold ${slip.status === 'diambil'
                            ? 'bg-green-100 text-green-800'
                            : 'bg-yellow-100 text-yellow-800'
                          }`}>
                          {slip.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        <button
                          onClick={() => handleViewDetail(slip)}
                          className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded text-xs"
                        >
                          Detail
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className="mt-4 text-sm text-gray-600">
            Showing {salarySlips.length} {salarySlips.length === 1 ? 'entry' : 'entries'}
          </div>
        </div>

        {/* DETAILS MODAL */}
        {selectedSlip && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4" onClick={() => setSelectedSlip(null)}>
            <div className="bg-white rounded-xl shadow-2xl w-full max-w-lg overflow-hidden" onClick={(e) => e.stopPropagation()}>
              <div className="bg-gray-50 px-6 py-4 border-b border-gray-200 flex justify-between items-center">
                <h3 className="text-lg font-bold text-gray-900">Detail Gaji - {selectedSlip.userName}</h3>
                <button onClick={() => setSelectedSlip(null)} className="text-gray-400 hover:text-gray-500">
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              <div className="p-6 max-h-[70vh] overflow-y-auto">
                {/* Header Info */}
                <div className="grid grid-cols-2 gap-4 mb-6 text-sm">
                  <div>
                    <p className="text-gray-500">Periode</p>
                    <p className="font-semibold text-gray-900">{selectedSlip.month} {selectedSlip.year}</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Status</p>
                    <span className={`inline-block px-2 py-0.5 rounded-full text-xs font-semibold ${selectedSlip.status === 'diambil' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
                      }`}>
                      {selectedSlip.status}
                    </span>
                  </div>
                </div>

                <hr className="my-4 border-gray-100" />

                {/* Penerimaan Section */}
                <h4 className="text-sm font-bold text-green-700 uppercase tracking-wide mb-3">Penerimaan</h4>
                <div className="space-y-2 mb-6">
                  {selectedSlip.details
                    .filter((d: any) => d.kategori === 'penerimaan')
                    .map((item: any, idx: number) => (
                      <div key={idx} className="flex justify-between text-sm">
                        <span className="text-gray-600">{item.nama_komponen}</span>
                        <span className="font-medium text-gray-900">{formatCurrency(item.jumlah)}</span>
                      </div>
                    ))}
                  {selectedSlip.details.filter((d: any) => d.kategori === 'penerimaan').length === 0 && (
                    <p className="text-xs text-gray-400 italic">Tidak ada data penerimaan</p>
                  )}
                  <div className="flex justify-between text-sm font-bold pt-2 border-t border-gray-100 mt-2">
                    <span>Total Penerimaan</span>
                    <span className="text-green-600">{formatCurrency(selectedSlip.basicSalary + selectedSlip.allowance)}</span>
                  </div>
                </div>

                {/* Potongan Section */}
                <h4 className="text-sm font-bold text-red-700 uppercase tracking-wide mb-3">Potongan</h4>
                <div className="space-y-2 mb-6">
                  {selectedSlip.details
                    .filter((d: any) => d.kategori === 'potongan')
                    .map((item: any, idx: number) => (
                      <div key={idx} className="flex justify-between text-sm">
                        <span className="text-gray-600">{item.nama_komponen}</span>
                        <span className="font-medium text-red-600">-{formatCurrency(item.jumlah)}</span>
                      </div>
                    ))}
                  {selectedSlip.details.filter((d: any) => d.kategori === 'potongan').length === 0 && (
                    <p className="text-xs text-gray-400 italic">Tidak ada data potongan</p>
                  )}
                  <div className="flex justify-between text-sm font-bold pt-2 border-t border-gray-100 mt-2">
                    <span>Total Potongan</span>
                    <span className="text-red-600">-{formatCurrency(selectedSlip.deductions)}</span>
                  </div>
                </div>

                {/* Grand Total */}
                <div className="bg-gray-50 rounded-lg p-4 flex justify-between items-center">
                  <span className="text-base font-bold text-gray-900">Take Home Pay</span>
                  <span className="text-xl font-bold text-blue-700">{formatCurrency(selectedSlip.totalSalary)}</span>
                </div>
              </div>
            </div>
          </div>
        )}

      </div>
    </DashboardLayout>
  );
}
