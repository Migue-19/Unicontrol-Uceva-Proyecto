import { db, User } from "./mockData";

const SESSION_KEY = "unicontrol_session";

export const authService = {
  register(data: Omit<User, "id">): { success: boolean; message: string } {
    const users = db.getUsers();

    if (!data.correo.endsWith("@uceva.edu.co")) {
      return { success: false, message: "El correo debe ser @uceva.edu.co" };
    }

    if (users.find((u) => u.correo === data.correo)) {
      return { success: false, message: "Ya existe una cuenta con este correo" };
    }

    if (users.find((u) => u.codigo === data.codigo)) {
      return { success: false, message: "Ya existe una cuenta con este código" };
    }

    if (data.password.length < 6) {
      return { success: false, message: "La contraseña debe tener al menos 6 caracteres" };
    }

    const newUser: User = { ...data, id: crypto.randomUUID() };
    db.setUsers([...users, newUser]);

    return { success: true, message: "Registro exitoso" };
  },

  login(correo: string, password: string): { success: boolean; message: string; user?: User } {
    const users = db.getUsers();
    const user = users.find((u) => u.correo === correo && u.password === password);

    if (!user) {
      return { success: false, message: "Correo o contraseña incorrectos" };
    }

    const { password: _, ...safeUser } = user;
    sessionStorage.setItem(SESSION_KEY, JSON.stringify(safeUser));

    return { success: true, message: "Inicio de sesión exitoso", user };
  },

  logout() {
    sessionStorage.removeItem(SESSION_KEY);
  },

  getCurrentUser(): User | null {
    const data = sessionStorage.getItem(SESSION_KEY);
    if (!data) return null;
    try {
      return JSON.parse(data) as User;
    } catch {
      return null;
    }
  },

  isAuthenticated(): boolean {
    return !!this.getCurrentUser();
  },
};
