export interface User {
  id: string;
  nombre: string;
  codigo: string;
  correo: string;
  password: string;
  carrera: string;
  semestre: number;
}

export interface Subject {
  id: string;
  codigo: string;
  nombre: string;
  creditos: number;
  horario: string;
  cuposTotal: number;
  cuposDisponibles: number;
  carrera: string;
  semestre: number;
}

export interface Enrollment {
  id: string;
  userId: string;
  subjectId: string;
  fecha: string;
}

export const carreras = [
  "Ingeniería de Sistemas",
  "Ingeniería Industrial",
  "Ingeniería Ambiental",
  "Contaduría Pública",
  "Administración de Empresas",
  "Enfermería",
  "Licenciatura en Educación Física",
];

export const mockSubjects: Subject[] = [
  { id: "s1", codigo: "IS101", nombre: "Programación I", creditos: 4, horario: "Lun-Mié 7:00-9:00", cuposTotal: 35, cuposDisponibles: 12, carrera: "Ingeniería de Sistemas", semestre: 1 },
  { id: "s2", codigo: "IS102", nombre: "Cálculo Diferencial", creditos: 4, horario: "Mar-Jue 9:00-11:00", cuposTotal: 40, cuposDisponibles: 8, carrera: "Ingeniería de Sistemas", semestre: 1 },
  { id: "s3", codigo: "IS103", nombre: "Álgebra Lineal", creditos: 3, horario: "Vie 7:00-10:00", cuposTotal: 35, cuposDisponibles: 15, carrera: "Ingeniería de Sistemas", semestre: 1 },
  { id: "s4", codigo: "IS201", nombre: "Programación II", creditos: 4, horario: "Lun-Mié 9:00-11:00", cuposTotal: 30, cuposDisponibles: 5, carrera: "Ingeniería de Sistemas", semestre: 2 },
  { id: "s5", codigo: "IS202", nombre: "Cálculo Integral", creditos: 4, horario: "Mar-Jue 7:00-9:00", cuposTotal: 40, cuposDisponibles: 20, carrera: "Ingeniería de Sistemas", semestre: 2 },
  { id: "s6", codigo: "IS203", nombre: "Física Mecánica", creditos: 3, horario: "Vie 10:00-13:00", cuposTotal: 35, cuposDisponibles: 0, carrera: "Ingeniería de Sistemas", semestre: 2 },
  { id: "s7", codigo: "IS301", nombre: "Estructuras de Datos", creditos: 4, horario: "Lun-Mié 11:00-13:00", cuposTotal: 30, cuposDisponibles: 10, carrera: "Ingeniería de Sistemas", semestre: 3 },
  { id: "s8", codigo: "IS302", nombre: "Bases de Datos", creditos: 3, horario: "Mar-Jue 11:00-13:00", cuposTotal: 30, cuposDisponibles: 7, carrera: "Ingeniería de Sistemas", semestre: 3 },
  { id: "s9", codigo: "IS303", nombre: "Ecuaciones Diferenciales", creditos: 3, horario: "Vie 13:00-16:00", cuposTotal: 35, cuposDisponibles: 18, carrera: "Ingeniería de Sistemas", semestre: 3 },
  { id: "s10", codigo: "II101", nombre: "Introducción a la Ingeniería Industrial", creditos: 2, horario: "Lun 7:00-9:00", cuposTotal: 40, cuposDisponibles: 25, carrera: "Ingeniería Industrial", semestre: 1 },
  { id: "s11", codigo: "II102", nombre: "Cálculo Diferencial", creditos: 4, horario: "Mar-Jue 9:00-11:00", cuposTotal: 40, cuposDisponibles: 14, carrera: "Ingeniería Industrial", semestre: 1 },
  { id: "s12", codigo: "II103", nombre: "Química General", creditos: 3, horario: "Mié-Vie 7:00-9:00", cuposTotal: 35, cuposDisponibles: 10, carrera: "Ingeniería Industrial", semestre: 1 },
  { id: "s13", codigo: "II201", nombre: "Estadística I", creditos: 3, horario: "Lun-Mié 9:00-11:00", cuposTotal: 35, cuposDisponibles: 12, carrera: "Ingeniería Industrial", semestre: 2 },
  { id: "s14", codigo: "II202", nombre: "Física Mecánica", creditos: 4, horario: "Mar-Jue 11:00-13:00", cuposTotal: 30, cuposDisponibles: 6, carrera: "Ingeniería Industrial", semestre: 2 },
  { id: "s15", codigo: "CP101", nombre: "Contabilidad Básica", creditos: 3, horario: "Lun-Mié 7:00-9:00", cuposTotal: 40, cuposDisponibles: 20, carrera: "Contaduría Pública", semestre: 1 },
  { id: "s16", codigo: "CP102", nombre: "Matemáticas Financieras", creditos: 3, horario: "Mar-Jue 9:00-11:00", cuposTotal: 35, cuposDisponibles: 15, carrera: "Contaduría Pública", semestre: 1 },
  { id: "s17", codigo: "AE101", nombre: "Fundamentos de Administración", creditos: 3, horario: "Lun-Mié 9:00-11:00", cuposTotal: 40, cuposDisponibles: 22, carrera: "Administración de Empresas", semestre: 1 },
  { id: "s18", codigo: "AE102", nombre: "Microeconomía", creditos: 3, horario: "Mar-Jue 7:00-9:00", cuposTotal: 35, cuposDisponibles: 18, carrera: "Administración de Empresas", semestre: 1 },
];

// In-memory databases
let users: User[] = [];
let enrollments: Enrollment[] = [];
let subjects: Subject[] = [...mockSubjects];

export const db = {
  getUsers: () => users,
  setUsers: (u: User[]) => { users = u; },
  getSubjects: () => subjects,
  setSubjects: (s: Subject[]) => { subjects = s; },
  getEnrollments: () => enrollments,
  setEnrollments: (e: Enrollment[]) => { enrollments = e; },
};
