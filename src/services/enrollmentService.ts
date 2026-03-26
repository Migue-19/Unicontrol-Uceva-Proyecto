import { db, Enrollment, Subject } from "./mockData";
import { subjectService } from "./subjectService";

export const enrollmentService = {
  getByUser(userId: string): (Enrollment & { subject: Subject })[] {
    const enrollments = db.getEnrollments().filter((e) => e.userId === userId);
    return enrollments
      .map((e) => {
        const subject = subjectService.getById(e.subjectId);
        return subject ? { ...e, subject } : null;
      })
      .filter(Boolean) as (Enrollment & { subject: Subject })[];
  },

  getTotalCredits(userId: string): number {
    return this.getByUser(userId).reduce((sum, e) => sum + e.subject.creditos, 0);
  },

  enroll(userId: string, subjectId: string): { success: boolean; message: string } {
    const subject = subjectService.getById(subjectId);
    if (!subject) return { success: false, message: "Materia no encontrada" };

    if (subject.cuposDisponibles <= 0) {
      return { success: false, message: "No hay cupos disponibles" };
    }

    const existing = db.getEnrollments();
    if (existing.find((e) => e.userId === userId && e.subjectId === subjectId)) {
      return { success: false, message: "Ya estás inscrito en esta materia" };
    }

    // Check schedule conflict
    const userEnrollments = this.getByUser(userId);
    const conflict = userEnrollments.find((e) => e.subject.horario === subject.horario);
    if (conflict) {
      return { success: false, message: `Conflicto de horario con ${conflict.subject.nombre}` };
    }

    const currentCredits = this.getTotalCredits(userId);
    if (currentCredits + subject.creditos > 21) {
      return { success: false, message: `Excede el máximo de 21 créditos (actual: ${currentCredits}, intentando agregar: ${subject.creditos})` };
    }

    const enrollment: Enrollment = {
      id: crypto.randomUUID(),
      userId,
      subjectId,
      fecha: new Date().toISOString(),
    };

    db.setEnrollments([...existing, enrollment]);
    subjectService.updateCupos(subjectId, -1);

    return { success: true, message: `Inscrito exitosamente en ${subject.nombre}` };
  },

  cancel(userId: string, subjectId: string): { success: boolean; message: string } {
    const existing = db.getEnrollments();
    const enrollment = existing.find((e) => e.userId === userId && e.subjectId === subjectId);

    if (!enrollment) {
      return { success: false, message: "No estás inscrito en esta materia" };
    }

    db.setEnrollments(existing.filter((e) => e.id !== enrollment.id));
    subjectService.updateCupos(subjectId, 1);

    const subject = subjectService.getById(subjectId);
    return { success: true, message: `Materia ${subject?.nombre || ""} cancelada exitosamente` };
  },
};
