export interface User {
  id: string;
  name: string;
  phone: string;
  password?: string;
  faceImage: string;
  todayAbsention?: 'alpha' | 'attend' | 'permission' | 'sick';
}

export interface Absention {
  id: string;
  userId: string;
  datetime: string;
  absention: 'alpha' | 'attend' | 'permission' | 'sick';
}
