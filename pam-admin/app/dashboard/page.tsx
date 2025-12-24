'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import DashboardLayout from '@/components/DashboardLayout';
import { getUsers, createUser, updateUser, updateAttendanceStatus } from '@/lib/api';
import { User } from '@/types';

export default function DashboardPage() {
  const router = useRouter();
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [modalType, setModalType] = useState<'password' | 'absention' | 'add' | 'image'>('password');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [newPassword, setNewPassword] = useState('');
  const [newAbsention, setNewAbsention] = useState<'alpha' | 'attend' | 'permission' | 'sick'>('attend');
  const [showImageModal, setShowImageModal] = useState(false);
  const [selectedImage, setSelectedImage] = useState<{ src: string; name: string } | null>(null);

  // New user form state
  const [newUser, setNewUser] = useState({
    name: '',
    phone: '',
    password: '',
    faceImage: '',
  });

  useEffect(() => {
    const isAuth = localStorage.getItem('isAuthenticated');
    if (!isAuth) {
      router.push('/login');
      return;
    }

    // Fetch users from API
    loadUsers();
  }, [router]);

  const loadUsers = async () => {
    try {
      setLoading(true);
      const response = await getUsers();
      if (response.success) {
        setUsers(response.users);
      }
    } catch (error) {
      console.error('Error loading users:', error);
      alert('Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('isAuthenticated');
    router.push('/login');
  };

  const openModal = (type: 'password' | 'absention' | 'add' | 'image', user?: User) => {
    setModalType(type);
    setSelectedUser(user || null);
    setShowModal(true);
    setNewPassword('');
    setNewAbsention('attend');
  };

  const openImageModal = (imageSrc: string, userName: string) => {
    setSelectedImage({ src: imageSrc, name: userName });
    setShowImageModal(true);
  };

  const handleChangePassword = async () => {
    if (selectedUser && newPassword) {
      try {
        await updateUser(selectedUser.id, { password: newPassword });
        alert(`Password changed successfully for ${selectedUser.name}`);
        setShowModal(false);
        loadUsers(); // Reload users
      } catch (error) {
        console.error('Error changing password:', error);
        alert('Failed to change password');
      }
    }
  };

  const handleAlterAbsention = async () => {
    if (selectedUser) {
      try {
        // Get today's date in YYYY-MM-DD format
        const today = new Date().toISOString().split('T')[0];

        // Map absention types to status
        const statusMap: Record<string, 'alpha' | 'permission' | 'sick' | 'attend'> = {
          'attend': 'attend',
          'alpha': 'alpha',
          'permission': 'permission',
          'sick': 'sick'
        };

        const status = statusMap[newAbsention as keyof typeof statusMap] || 'alpha';

        // Call API to update status
        await updateAttendanceStatus(selectedUser.id, today, status);

        // Update local state
        const updatedUsers = users.map(u =>
          u.id === selectedUser.id ? { ...u, todayAbsention: newAbsention } : u
        );
        setUsers(updatedUsers);
        alert(`Absention updated successfully for ${selectedUser.name}`);
        setShowModal(false);
      } catch (error) {
        console.error('Error updating absention:', error);
        alert('Failed to update absention status');
      }
    }
  };

  const handleAddUser = async () => {
    if (newUser.name && newUser.phone && newUser.password) {
      try {
        await createUser({
          name: newUser.name,
          phone: newUser.phone,
          password: newUser.password,
          faceImage: newUser.faceImage || '/images/avatar-placeholder.png',
        });
        alert('User added successfully');
        setShowModal(false);
        setNewUser({ name: '', phone: '', password: '', faceImage: '' });
        loadUsers(); // Reload users
      } catch (error) {
        console.error('Error adding user:', error);
        alert('Failed to add user');
      }
    }
  };

  const getAbsentionBadgeColor = (absention: string) => {
    switch (absention) {
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
            <h1 className="text-2xl font-bold text-gray-900">User List</h1>
            <button
              onClick={() => openModal('add')}
              className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              <span>Add New User</span>
            </button>
          </div>

          {/* User Table */}
          <div className="overflow-x-auto">
            {loading ? (
              <div className="text-center py-8 text-gray-500">Loading users...</div>
            ) : (
              <table className="w-full">
                <thead>
                  <tr className="bg-gray-50 border-b border-gray-200">
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">No.</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Phone</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Face Image</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Today Absention</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {users.map((user, index) => (
                    <tr key={user.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{index + 1}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{user.name}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">{user.phone}</td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <button
                          onClick={() => openImageModal(user.faceImage, user.name)}
                          className="w-10 h-10 rounded-full overflow-hidden bg-gray-200 hover:ring-2 hover:ring-blue-500 transition cursor-pointer"
                        >
                          <Image
                            src={`https://hypocycloidal-intensely-raven.ngrok-free.dev/${user.faceImage}`}
                            alt={`${user.name}'s face`}
                            width={40}
                            height={40}
                            className="w-full h-full object-cover"
                          />
                        </button>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <button
                          onClick={() => router.push(`/dashboard/absention/${user.id}`)}
                          className={`px-3 py-1 rounded-full text-xs font-semibold ${getAbsentionBadgeColor(user.todayAbsention || 'alpha')} hover:opacity-80 transition cursor-pointer`}
                        >
                          {user.todayAbsention || 'alpha'}
                        </button>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm space-x-2">
                        <button
                          onClick={() => openModal('password', user)}
                          className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 transition text-xs"
                        >
                          Change Password
                        </button>
                        <button
                          onClick={() => openModal('absention', user)}
                          className="px-3 py-1 bg-yellow-600 text-white rounded hover:bg-yellow-700 transition text-xs"
                        >
                          Alter Absention
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          <div className="mt-4 text-sm text-gray-600">
            Showing 1 to {users.length} of {users.length} entries
          </div>
        </div>

        {/* Modal */}
        {showModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl shadow-2xl p-6 w-full max-w-md">
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold text-gray-900">
                  {modalType === 'password' && 'Change Password'}
                  {modalType === 'absention' && 'Alter Absention'}
                  {modalType === 'add' && 'Add New User'}
                </h2>
                <button
                  onClick={() => setShowModal(false)}
                  className="text-gray-500 hover:text-gray-700"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>

              {modalType === 'password' && selectedUser && (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">User</label>
                    <input
                      type="text"
                      value={selectedUser.name}
                      disabled
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-50"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">New Password</label>
                    <input
                      type="text"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                      placeholder="Enter new password"
                    />
                  </div>
                  <button
                    onClick={handleChangePassword}
                    className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 transition"
                  >
                    Change Password
                  </button>
                </div>
              )}

              {modalType === 'absention' && selectedUser && (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">User</label>
                    <input
                      type="text"
                      value={selectedUser.name}
                      disabled
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-50"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Absention Status</label>
                    <select
                      value={newAbsention}
                      onChange={(e) => setNewAbsention(e.target.value as any)}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                    >
                      <option value="attend">Attend</option>
                      <option value="alpha">Alpha</option>
                      <option value="permission">Permission</option>
                      <option value="sick">Sick</option>
                    </select>
                  </div>
                  <button
                    onClick={handleAlterAbsention}
                    className="w-full bg-yellow-600 text-white py-2 rounded-lg hover:bg-yellow-700 transition"
                  >
                    Update Absention
                  </button>
                </div>
              )}

              {modalType === 'add' && (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Name</label>
                    <input
                      type="text"
                      value={newUser.name}
                      onChange={(e) => setNewUser({ ...newUser, name: e.target.value })}
                      className="w-full px-4 py-2 border text-black border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                      placeholder="Enter name"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Phone</label>
                    <input
                      type="text"
                      value={newUser.phone}
                      onChange={(e) => setNewUser({ ...newUser, phone: e.target.value })}
                      className="w-full px-4 py-2 border text-black border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                      placeholder="Enter phone number"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Password</label>
                    <input
                      type="text"
                      value={newUser.password}
                      onChange={(e) => setNewUser({ ...newUser, password: e.target.value })}
                      className="w-full px-4 py-2 border text-black border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                      placeholder="Enter password"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">Face Image URL (optional)</label>
                    <input
                      type="text"
                      value={newUser.faceImage}
                      onChange={(e) => setNewUser({ ...newUser, faceImage: e.target.value })}
                      className="w-full px-4 py-2 border text-black border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none"
                      placeholder="Enter image URL"
                    />
                  </div>
                  <button
                    onClick={handleAddUser}
                    className="w-full bg-blue-600 text-white py-2 rounded-lg
                  
                  
                  
                  
                  hover:bg-blue-700 transition"
                  >
                    Add User
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Image Modal */}
        {showImageModal && selectedImage && (
          <div
            className="fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4"
            onClick={() => setShowImageModal(false)}
          >
            <div
              className="relative bg-white rounded-xl shadow-2xl p-4 max-w-2xl w-full"
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex justify-between items-center mb-4">
                <h2 className="text-xl font-bold text-gray-900">{selectedImage.name}&apos;s Face Image</h2>
                <button
                  onClick={() => setShowImageModal(false)}
                  className="text-gray-500 hover:text-gray-700 transition"
                >
                  <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div className="relative w-full aspect-square bg-gray-100 rounded-lg overflow-hidden">
                <Image
                  src={`https://hypocycloidal-intensely-raven.ngrok-free.dev/${selectedImage.src}`}
                  alt={`${selectedImage.name}'s face`}
                  fill
                  className="object-contain"
                  sizes="(max-width: 768px) 100vw, 672px"
                />
              </div>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
