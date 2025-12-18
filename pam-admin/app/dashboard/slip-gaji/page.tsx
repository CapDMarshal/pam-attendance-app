'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import DashboardLayout from '@/components/DashboardLayout';
import { getUsers } from '@/lib/api';

interface SalarySlip {
  userId: string;
  userName: string;
  month: string;
  year: number;
  basicSalary: number;
  allowance: number;
  deductions: number;
  totalSalary: number;
}

export default function SlipGajiPage() {
  const router = useRouter();
  const [selectedMonth, setSelectedMonth] = useState(new Date().getMonth());
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
  const [salarySlips, setSalarySlips] = useState<SalarySlip[]>([]);
  const [loading, setLoading] = useState(true);

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
      // Fetch all users first
      const usersResponse = await getUsers();

      if (usersResponse.success) {
        const monthStr = `${selectedYear}-${(selectedMonth + 1).toString().padStart(2, '0')}`;

        // Fetch salary data for each user
        const slipsPromises = usersResponse.users.map(async (user) => {
          try {
            const salaryResponse = await fetch(
              `http://localhost:5000/api/salary/${user.id}/slip/${monthStr}`
            );

            if (salaryResponse.ok) {
              const data = await salaryResponse.json();

              // Check if response has the expected structure
              if (data.success && data.salary) {
                const salary = data.salary;

                return {
                  userId: user.id,
                  userName: user.name,
                  month: getMonthName(selectedMonth),
                  year: selectedYear,
                  basicSalary: salary.basicSalary,
                  allowance: salary.allowances,
                  deductions: salary.deductions,
                  totalSalary: salary.netSalary
                };
              }
            }
          } catch (err) {
            console.error(`Error fetching salary for user ${user.id}:`, err);
          }

          // Return null if fetch failed
          return null;
        });

        const slips = (await Promise.all(slipsPromises)).filter((slip): slip is SalarySlip => slip !== null);
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
      </div>
    </DashboardLayout>
  );
}
