import { User, Absention } from '@/types';

export const mockUsers: User[] = [
  {
    id: '1',
    name: 'Yanto',
    phone: '08592848928',
    password: 'password123',
    faceImage: '/images/man_face.jpeg',
    todayAbsention: 'attend'
  },
  {
    id: '2',
    name: 'Painah',
    phone: '08592849990',
    password: 'password123',
    faceImage: '/images/girl_face.jpeg',
    todayAbsention: 'attend'
  },
  {
    id: '3',
    name: 'Laila',
    phone: '08592849956',
    password: 'password123',
    faceImage: '/images/girl_face.jpeg',
    todayAbsention: 'permission'
  },
  {
    id: '4',
    name: 'Supardi',
    phone: '08592849924',
    password: 'password123',
    faceImage: '/images/man_face.jpeg',
    todayAbsention: 'sick'
  },
];

export const mockAbsentions: Absention[] = [
  // November 2025 (Current Month)
  // User 1 - Yanto
  {
    id: '1',
    userId: '1',
    datetime: '2025-11-19T08:00:00',
    absention: 'attend'
  },
  {
    id: '2',
    userId: '1',
    datetime: '2025-11-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '3',
    userId: '1',
    datetime: '2025-11-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '4',
    userId: '1',
    datetime: '2025-11-14T08:00:00',
    absention: 'attend'
  },
  {
    id: '5',
    userId: '1',
    datetime: '2025-11-13T08:00:00',
    absention: 'attend'
  },
  {
    id: '6',
    userId: '1',
    datetime: '2025-11-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '7',
    userId: '1',
    datetime: '2025-11-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '8',
    userId: '1',
    datetime: '2025-11-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '9',
    userId: '1',
    datetime: '2025-11-07T08:00:00',
    absention: 'attend'
  },
  {
    id: '10',
    userId: '1',
    datetime: '2025-11-06T08:00:00',
    absention: 'attend'
  },
  {
    id: '11',
    userId: '1',
    datetime: '2025-11-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '12',
    userId: '1',
    datetime: '2025-11-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '13',
    userId: '1',
    datetime: '2025-11-01T08:00:00',
    absention: 'attend'
  },
  
  // User 2 - Painah
  {
    id: '14',
    userId: '2',
    datetime: '2025-11-19T08:00:00',
    absention: 'attend'
  },
  {
    id: '15',
    userId: '2',
    datetime: '2025-11-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '16',
    userId: '2',
    datetime: '2025-11-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '17',
    userId: '2',
    datetime: '2025-11-14T08:00:00',
    absention: 'alpha'
  },
  {
    id: '18',
    userId: '2',
    datetime: '2025-11-13T08:00:00',
    absention: 'attend'
  },
  {
    id: '19',
    userId: '2',
    datetime: '2025-11-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '20',
    userId: '2',
    datetime: '2025-11-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '21',
    userId: '2',
    datetime: '2025-11-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '22',
    userId: '2',
    datetime: '2025-11-07T08:00:00',
    absention: 'alpha'
  },
  {
    id: '23',
    userId: '2',
    datetime: '2025-11-06T08:00:00',
    absention: 'attend'
  },
  {
    id: '24',
    userId: '2',
    datetime: '2025-11-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '25',
    userId: '2',
    datetime: '2025-11-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '26',
    userId: '2',
    datetime: '2025-11-01T08:00:00',
    absention: 'attend'
  },
  
  // User 3 - Laila
  {
    id: '27',
    userId: '3',
    datetime: '2025-11-19T08:00:00',
    absention: 'permission'
  },
  {
    id: '28',
    userId: '3',
    datetime: '2025-11-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '29',
    userId: '3',
    datetime: '2025-11-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '30',
    userId: '3',
    datetime: '2025-11-14T08:00:00',
    absention: 'attend'
  },
  {
    id: '31',
    userId: '3',
    datetime: '2025-11-13T08:00:00',
    absention: 'attend'
  },
  {
    id: '32',
    userId: '3',
    datetime: '2025-11-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '33',
    userId: '3',
    datetime: '2025-11-11T08:00:00',
    absention: 'permission'
  },
  {
    id: '34',
    userId: '3',
    datetime: '2025-11-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '35',
    userId: '3',
    datetime: '2025-11-07T08:00:00',
    absention: 'attend'
  },
  {
    id: '36',
    userId: '3',
    datetime: '2025-11-06T08:00:00',
    absention: 'attend'
  },
  {
    id: '37',
    userId: '3',
    datetime: '2025-11-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '38',
    userId: '3',
    datetime: '2025-11-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '39',
    userId: '3',
    datetime: '2025-11-01T08:00:00',
    absention: 'attend'
  },
  
  // User 4 - Supardi
  {
    id: '40',
    userId: '4',
    datetime: '2025-11-19T08:00:00',
    absention: 'sick'
  },
  {
    id: '41',
    userId: '4',
    datetime: '2025-11-18T08:00:00',
    absention: 'sick'
  },
  {
    id: '42',
    userId: '4',
    datetime: '2025-11-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '43',
    userId: '4',
    datetime: '2025-11-14T08:00:00',
    absention: 'attend'
  },
  {
    id: '44',
    userId: '4',
    datetime: '2025-11-13T08:00:00',
    absention: 'attend'
  },
  {
    id: '45',
    userId: '4',
    datetime: '2025-11-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '46',
    userId: '4',
    datetime: '2025-11-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '47',
    userId: '4',
    datetime: '2025-11-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '48',
    userId: '4',
    datetime: '2025-11-07T08:00:00',
    absention: 'attend'
  },
  {
    id: '49',
    userId: '4',
    datetime: '2025-11-06T08:00:00',
    absention: 'attend'
  },
  {
    id: '50',
    userId: '4',
    datetime: '2025-11-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '51',
    userId: '4',
    datetime: '2025-11-04T08:00:00',
    absention: 'alpha'
  },
  {
    id: '52',
    userId: '4',
    datetime: '2025-11-01T08:00:00',
    absention: 'attend'
  },

  // October 2025 (Previous Month)
  // User 1 - Yanto
  {
    id: '53',
    userId: '1',
    datetime: '2025-10-31T08:00:00',
    absention: 'attend'
  },
  {
    id: '54',
    userId: '1',
    datetime: '2025-10-30T08:00:00',
    absention: 'attend'
  },
  {
    id: '55',
    userId: '1',
    datetime: '2025-10-29T08:00:00',
    absention: 'attend'
  },
  {
    id: '56',
    userId: '1',
    datetime: '2025-10-28T08:00:00',
    absention: 'attend'
  },
  {
    id: '57',
    userId: '1',
    datetime: '2025-10-25T08:00:00',
    absention: 'attend'
  },
  {
    id: '58',
    userId: '1',
    datetime: '2025-10-24T08:00:00',
    absention: 'attend'
  },
  {
    id: '59',
    userId: '1',
    datetime: '2025-10-23T08:00:00',
    absention: 'attend'
  },
  {
    id: '60',
    userId: '1',
    datetime: '2025-10-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '61',
    userId: '1',
    datetime: '2025-10-21T08:00:00',
    absention: 'attend'
  },
  {
    id: '62',
    userId: '1',
    datetime: '2025-10-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '63',
    userId: '1',
    datetime: '2025-10-17T08:00:00',
    absention: 'attend'
  },
  {
    id: '64',
    userId: '1',
    datetime: '2025-10-16T08:00:00',
    absention: 'alpha'
  },
  {
    id: '65',
    userId: '1',
    datetime: '2025-10-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '66',
    userId: '1',
    datetime: '2025-10-14T08:00:00',
    absention: 'attend'
  },
  {
    id: '67',
    userId: '1',
    datetime: '2025-10-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '68',
    userId: '1',
    datetime: '2025-10-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '69',
    userId: '1',
    datetime: '2025-10-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '70',
    userId: '1',
    datetime: '2025-10-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '71',
    userId: '1',
    datetime: '2025-10-07T08:00:00',
    absention: 'attend'
  },
  {
    id: '72',
    userId: '1',
    datetime: '2025-10-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '73',
    userId: '1',
    datetime: '2025-10-03T08:00:00',
    absention: 'attend'
  },
  {
    id: '74',
    userId: '1',
    datetime: '2025-10-02T08:00:00',
    absention: 'attend'
  },
  {
    id: '75',
    userId: '1',
    datetime: '2025-10-01T08:00:00',
    absention: 'attend'
  },

  // User 2 - Painah
  {
    id: '76',
    userId: '2',
    datetime: '2025-10-31T08:00:00',
    absention: 'attend'
  },
  {
    id: '77',
    userId: '2',
    datetime: '2025-10-30T08:00:00',
    absention: 'attend'
  },
  {
    id: '78',
    userId: '2',
    datetime: '2025-10-29T08:00:00',
    absention: 'alpha'
  },
  {
    id: '79',
    userId: '2',
    datetime: '2025-10-28T08:00:00',
    absention: 'attend'
  },
  {
    id: '80',
    userId: '2',
    datetime: '2025-10-25T08:00:00',
    absention: 'attend'
  },
  {
    id: '81',
    userId: '2',
    datetime: '2025-10-24T08:00:00',
    absention: 'attend'
  },
  {
    id: '82',
    userId: '2',
    datetime: '2025-10-23T08:00:00',
    absention: 'alpha'
  },
  {
    id: '83',
    userId: '2',
    datetime: '2025-10-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '84',
    userId: '2',
    datetime: '2025-10-21T08:00:00',
    absention: 'attend'
  },
  {
    id: '85',
    userId: '2',
    datetime: '2025-10-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '86',
    userId: '2',
    datetime: '2025-10-17T08:00:00',
    absention: 'attend'
  },
  {
    id: '87',
    userId: '2',
    datetime: '2025-10-16T08:00:00',
    absention: 'attend'
  },
  {
    id: '88',
    userId: '2',
    datetime: '2025-10-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '89',
    userId: '2',
    datetime: '2025-10-14T08:00:00',
    absention: 'attend'
  },
  {
    id: '90',
    userId: '2',
    datetime: '2025-10-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '91',
    userId: '2',
    datetime: '2025-10-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '92',
    userId: '2',
    datetime: '2025-10-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '93',
    userId: '2',
    datetime: '2025-10-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '94',
    userId: '2',
    datetime: '2025-10-07T08:00:00',
    absention: 'attend'
  },
  {
    id: '95',
    userId: '2',
    datetime: '2025-10-04T08:00:00',
    absention: 'alpha'
  },
  {
    id: '96',
    userId: '2',
    datetime: '2025-10-03T08:00:00',
    absention: 'attend'
  },
  {
    id: '97',
    userId: '2',
    datetime: '2025-10-02T08:00:00',
    absention: 'attend'
  },
  {
    id: '98',
    userId: '2',
    datetime: '2025-10-01T08:00:00',
    absention: 'attend'
  },

  // User 3 - Laila
  {
    id: '99',
    userId: '3',
    datetime: '2025-10-31T08:00:00',
    absention: 'attend'
  },
  {
    id: '100',
    userId: '3',
    datetime: '2025-10-30T08:00:00',
    absention: 'attend'
  },
  {
    id: '101',
    userId: '3',
    datetime: '2025-10-29T08:00:00',
    absention: 'attend'
  },
  {
    id: '102',
    userId: '3',
    datetime: '2025-10-28T08:00:00',
    absention: 'permission'
  },
  {
    id: '103',
    userId: '3',
    datetime: '2025-10-25T08:00:00',
    absention: 'attend'
  },
  {
    id: '104',
    userId: '3',
    datetime: '2025-10-24T08:00:00',
    absention: 'attend'
  },
  {
    id: '105',
    userId: '3',
    datetime: '2025-10-23T08:00:00',
    absention: 'attend'
  },
  {
    id: '106',
    userId: '3',
    datetime: '2025-10-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '107',
    userId: '3',
    datetime: '2025-10-21T08:00:00',
    absention: 'attend'
  },
  {
    id: '108',
    userId: '3',
    datetime: '2025-10-18T08:00:00',
    absention: 'permission'
  },
  {
    id: '109',
    userId: '3',
    datetime: '2025-10-17T08:00:00',
    absention: 'attend'
  },
  {
    id: '110',
    userId: '3',
    datetime: '2025-10-16T08:00:00',
    absention: 'attend'
  },
  {
    id: '111',
    userId: '3',
    datetime: '2025-10-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '112',
    userId: '3',
    datetime: '2025-10-14T08:00:00',
    absention: 'attend'
  },
  {
    id: '113',
    userId: '3',
    datetime: '2025-10-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '114',
    userId: '3',
    datetime: '2025-10-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '115',
    userId: '3',
    datetime: '2025-10-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '116',
    userId: '3',
    datetime: '2025-10-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '117',
    userId: '3',
    datetime: '2025-10-07T08:00:00',
    absention: 'attend'
  },
  {
    id: '118',
    userId: '3',
    datetime: '2025-10-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '119',
    userId: '3',
    datetime: '2025-10-03T08:00:00',
    absention: 'permission'
  },
  {
    id: '120',
    userId: '3',
    datetime: '2025-10-02T08:00:00',
    absention: 'attend'
  },
  {
    id: '121',
    userId: '3',
    datetime: '2025-10-01T08:00:00',
    absention: 'attend'
  },

  // User 4 - Supardi
  {
    id: '122',
    userId: '4',
    datetime: '2025-10-31T08:00:00',
    absention: 'attend'
  },
  {
    id: '123',
    userId: '4',
    datetime: '2025-10-30T08:00:00',
    absention: 'attend'
  },
  {
    id: '124',
    userId: '4',
    datetime: '2025-10-29T08:00:00',
    absention: 'attend'
  },
  {
    id: '125',
    userId: '4',
    datetime: '2025-10-28T08:00:00',
    absention: 'attend'
  },
  {
    id: '126',
    userId: '4',
    datetime: '2025-10-25T08:00:00',
    absention: 'sick'
  },
  {
    id: '127',
    userId: '4',
    datetime: '2025-10-24T08:00:00',
    absention: 'sick'
  },
  {
    id: '128',
    userId: '4',
    datetime: '2025-10-23T08:00:00',
    absention: 'attend'
  },
  {
    id: '129',
    userId: '4',
    datetime: '2025-10-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '130',
    userId: '4',
    datetime: '2025-10-21T08:00:00',
    absention: 'attend'
  },
  {
    id: '131',
    userId: '4',
    datetime: '2025-10-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '132',
    userId: '4',
    datetime: '2025-10-17T08:00:00',
    absention: 'attend'
  },
  {
    id: '133',
    userId: '4',
    datetime: '2025-10-16T08:00:00',
    absention: 'attend'
  },
  {
    id: '134',
    userId: '4',
    datetime: '2025-10-15T08:00:00',
    absention: 'alpha'
  },
  {
    id: '135',
    userId: '4',
    datetime: '2025-10-14T08:00:00',
    absention: 'attend'
  },
  {
    id: '136',
    userId: '4',
    datetime: '2025-10-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '137',
    userId: '4',
    datetime: '2025-10-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '138',
    userId: '4',
    datetime: '2025-10-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '139',
    userId: '4',
    datetime: '2025-10-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '140',
    userId: '4',
    datetime: '2025-10-07T08:00:00',
    absention: 'attend'
  },
  {
    id: '141',
    userId: '4',
    datetime: '2025-10-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '142',
    userId: '4',
    datetime: '2025-10-03T08:00:00',
    absention: 'attend'
  },
  {
    id: '143',
    userId: '4',
    datetime: '2025-10-02T08:00:00',
    absention: 'attend'
  },
  {
    id: '144',
    userId: '4',
    datetime: '2025-10-01T08:00:00',
    absention: 'attend'
  },

  // September 2025
  // User 1 - Yanto (20 days, all attend)
  {
    id: '145',
    userId: '1',
    datetime: '2025-09-30T08:00:00',
    absention: 'attend'
  },
  {
    id: '146',
    userId: '1',
    datetime: '2025-09-29T08:00:00',
    absention: 'attend'
  },
  {
    id: '147',
    userId: '1',
    datetime: '2025-09-26T08:00:00',
    absention: 'attend'
  },
  {
    id: '148',
    userId: '1',
    datetime: '2025-09-25T08:00:00',
    absention: 'attend'
  },
  {
    id: '149',
    userId: '1',
    datetime: '2025-09-24T08:00:00',
    absention: 'attend'
  },
  {
    id: '150',
    userId: '1',
    datetime: '2025-09-23T08:00:00',
    absention: 'attend'
  },
  {
    id: '151',
    userId: '1',
    datetime: '2025-09-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '152',
    userId: '1',
    datetime: '2025-09-19T08:00:00',
    absention: 'attend'
  },
  {
    id: '153',
    userId: '1',
    datetime: '2025-09-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '154',
    userId: '1',
    datetime: '2025-09-17T08:00:00',
    absention: 'attend'
  },
  {
    id: '155',
    userId: '1',
    datetime: '2025-09-16T08:00:00',
    absention: 'attend'
  },
  {
    id: '156',
    userId: '1',
    datetime: '2025-09-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '157',
    userId: '1',
    datetime: '2025-09-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '158',
    userId: '1',
    datetime: '2025-09-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '159',
    userId: '1',
    datetime: '2025-09-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '160',
    userId: '1',
    datetime: '2025-09-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '161',
    userId: '1',
    datetime: '2025-09-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '162',
    userId: '1',
    datetime: '2025-09-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '163',
    userId: '1',
    datetime: '2025-09-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '164',
    userId: '1',
    datetime: '2025-09-03T08:00:00',
    absention: 'attend'
  },

  // User 2 - Painah (September - mixed)
  {
    id: '165',
    userId: '2',
    datetime: '2025-09-30T08:00:00',
    absention: 'attend'
  },
  {
    id: '166',
    userId: '2',
    datetime: '2025-09-29T08:00:00',
    absention: 'attend'
  },
  {
    id: '167',
    userId: '2',
    datetime: '2025-09-26T08:00:00',
    absention: 'alpha'
  },
  {
    id: '168',
    userId: '2',
    datetime: '2025-09-25T08:00:00',
    absention: 'attend'
  },
  {
    id: '169',
    userId: '2',
    datetime: '2025-09-24T08:00:00',
    absention: 'attend'
  },
  {
    id: '170',
    userId: '2',
    datetime: '2025-09-23T08:00:00',
    absention: 'attend'
  },
  {
    id: '171',
    userId: '2',
    datetime: '2025-09-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '172',
    userId: '2',
    datetime: '2025-09-19T08:00:00',
    absention: 'attend'
  },
  {
    id: '173',
    userId: '2',
    datetime: '2025-09-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '174',
    userId: '2',
    datetime: '2025-09-17T08:00:00',
    absention: 'alpha'
  },
  {
    id: '175',
    userId: '2',
    datetime: '2025-09-16T08:00:00',
    absention: 'attend'
  },
  {
    id: '176',
    userId: '2',
    datetime: '2025-09-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '177',
    userId: '2',
    datetime: '2025-09-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '178',
    userId: '2',
    datetime: '2025-09-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '179',
    userId: '2',
    datetime: '2025-09-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '180',
    userId: '2',
    datetime: '2025-09-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '181',
    userId: '2',
    datetime: '2025-09-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '182',
    userId: '2',
    datetime: '2025-09-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '183',
    userId: '2',
    datetime: '2025-09-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '184',
    userId: '2',
    datetime: '2025-09-03T08:00:00',
    absention: 'attend'
  },

  // User 3 - Laila (September - with permissions)
  {
    id: '185',
    userId: '3',
    datetime: '2025-09-30T08:00:00',
    absention: 'permission'
  },
  {
    id: '186',
    userId: '3',
    datetime: '2025-09-29T08:00:00',
    absention: 'permission'
  },
  {
    id: '187',
    userId: '3',
    datetime: '2025-09-26T08:00:00',
    absention: 'attend'
  },
  {
    id: '188',
    userId: '3',
    datetime: '2025-09-25T08:00:00',
    absention: 'attend'
  },
  {
    id: '189',
    userId: '3',
    datetime: '2025-09-24T08:00:00',
    absention: 'attend'
  },
  {
    id: '190',
    userId: '3',
    datetime: '2025-09-23T08:00:00',
    absention: 'attend'
  },
  {
    id: '191',
    userId: '3',
    datetime: '2025-09-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '192',
    userId: '3',
    datetime: '2025-09-19T08:00:00',
    absention: 'attend'
  },
  {
    id: '193',
    userId: '3',
    datetime: '2025-09-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '194',
    userId: '3',
    datetime: '2025-09-17T08:00:00',
    absention: 'attend'
  },
  {
    id: '195',
    userId: '3',
    datetime: '2025-09-16T08:00:00',
    absention: 'attend'
  },
  {
    id: '196',
    userId: '3',
    datetime: '2025-09-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '197',
    userId: '3',
    datetime: '2025-09-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '198',
    userId: '3',
    datetime: '2025-09-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '199',
    userId: '3',
    datetime: '2025-09-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '200',
    userId: '3',
    datetime: '2025-09-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '201',
    userId: '3',
    datetime: '2025-09-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '202',
    userId: '3',
    datetime: '2025-09-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '203',
    userId: '3',
    datetime: '2025-09-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '204',
    userId: '3',
    datetime: '2025-09-03T08:00:00',
    absention: 'attend'
  },

  // User 4 - Supardi (September - with sick days)
  {
    id: '205',
    userId: '4',
    datetime: '2025-09-30T08:00:00',
    absention: 'attend'
  },
  {
    id: '206',
    userId: '4',
    datetime: '2025-09-29T08:00:00',
    absention: 'attend'
  },
  {
    id: '207',
    userId: '4',
    datetime: '2025-09-26T08:00:00',
    absention: 'attend'
  },
  {
    id: '208',
    userId: '4',
    datetime: '2025-09-25T08:00:00',
    absention: 'sick'
  },
  {
    id: '209',
    userId: '4',
    datetime: '2025-09-24T08:00:00',
    absention: 'sick'
  },
  {
    id: '210',
    userId: '4',
    datetime: '2025-09-23T08:00:00',
    absention: 'sick'
  },
  {
    id: '211',
    userId: '4',
    datetime: '2025-09-22T08:00:00',
    absention: 'attend'
  },
  {
    id: '212',
    userId: '4',
    datetime: '2025-09-19T08:00:00',
    absention: 'attend'
  },
  {
    id: '213',
    userId: '4',
    datetime: '2025-09-18T08:00:00',
    absention: 'attend'
  },
  {
    id: '214',
    userId: '4',
    datetime: '2025-09-17T08:00:00',
    absention: 'attend'
  },
  {
    id: '215',
    userId: '4',
    datetime: '2025-09-16T08:00:00',
    absention: 'attend'
  },
  {
    id: '216',
    userId: '4',
    datetime: '2025-09-15T08:00:00',
    absention: 'attend'
  },
  {
    id: '217',
    userId: '4',
    datetime: '2025-09-12T08:00:00',
    absention: 'attend'
  },
  {
    id: '218',
    userId: '4',
    datetime: '2025-09-11T08:00:00',
    absention: 'attend'
  },
  {
    id: '219',
    userId: '4',
    datetime: '2025-09-10T08:00:00',
    absention: 'attend'
  },
  {
    id: '220',
    userId: '4',
    datetime: '2025-09-09T08:00:00',
    absention: 'attend'
  },
  {
    id: '221',
    userId: '4',
    datetime: '2025-09-08T08:00:00',
    absention: 'attend'
  },
  {
    id: '222',
    userId: '4',
    datetime: '2025-09-05T08:00:00',
    absention: 'attend'
  },
  {
    id: '223',
    userId: '4',
    datetime: '2025-09-04T08:00:00',
    absention: 'attend'
  },
  {
    id: '224',
    userId: '4',
    datetime: '2025-09-03T08:00:00',
    absention: 'attend'
  },
];
