import { db, Subject } from "./mockData";

export const subjectService = {
  getAll(): Subject[] {
    return db.getSubjects();
  },

  getByCarreraAndSemestre(carrera: string, semestre?: number): Subject[] {
    return db.getSubjects().filter(
      (s) => s.carrera === carrera && (semestre === undefined || s.semestre === semestre)
    );
  },

  getById(id: string): Subject | undefined {
    return db.getSubjects().find((s) => s.id === id);
  },

  updateCupos(id: string, delta: number): boolean {
    const subjects = db.getSubjects();
    const idx = subjects.findIndex((s) => s.id === id);
    if (idx === -1) return false;

    const newCupos = subjects[idx].cuposDisponibles + delta;
    if (newCupos < 0 || newCupos > subjects[idx].cuposTotal) return false;

    subjects[idx] = { ...subjects[idx], cuposDisponibles: newCupos };
    db.setSubjects([...subjects]);
    return true;
  },
};
