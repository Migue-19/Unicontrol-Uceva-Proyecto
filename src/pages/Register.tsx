import { useState, useEffect } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "@/hooks/useAuth";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { UserPlus, Loader2 } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface Facultad { id: string; nombre: string; }
interface Carrera { id: string; nombre: string; facultad_id: string; }

export default function Register() {
  const [form, setForm] = useState({
    nombre: "", codigo: "", correo: "", password: "",
    facultad_id: "", carrera_id: "", semestre: "",
  });
  const [facultades, setFacultades] = useState<Facultad[]>([]);
  const [carreras, setCarreras] = useState<Carrera[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const { register } = useAuth();
  const navigate = useNavigate();
  const { toast } = useToast();

  useEffect(() => {
    supabase.from("facultades").select("*").order("nombre").then(({ data }) => {
      if (data) setFacultades(data as Facultad[]);
    });
    supabase.from("carreras").select("*").order("nombre").then(({ data }) => {
      if (data) setCarreras(data as Carrera[]);
    });
  }, []);

  const filteredCarreras = carreras.filter(c => c.facultad_id === form.facultad_id);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.carrera_id) {
      toast({ title: "Error", description: "Selecciona una carrera", variant: "destructive" });
      return;
    }

    setSubmitting(true);
    const result = await register(form.correo, form.password, {
      nombre: form.nombre,
      codigo_estudiantil: form.codigo,
      carrera_id: form.carrera_id,
      semestre_actual: parseInt(form.semestre) || 1,
    });
    setSubmitting(false);

    if (result.success) {
      toast({ title: "¡Registro exitoso!", description: "Ahora inicia sesión" });
      navigate("/login");
    } else {
      toast({ title: "Error", description: result.message, variant: "destructive" });
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background px-4 py-8">
      <div className="w-full max-w-md animate-fade-in">
        <div className="flex flex-col items-center mb-6">
          <img src="https://www.uceva.edu.co/wp-content/uploads/2023/08/BANDERA-UCEVA.png" alt="UCEVA" className="h-14 mb-3" />
          <h1 className="font-display text-2xl font-bold text-foreground">Crear Cuenta</h1>
        </div>

        <Card className="glass-card">
          <CardHeader>
            <CardTitle className="font-display">Registro</CardTitle>
            <CardDescription>Completa tus datos para crear tu cuenta</CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="nombre">Nombre completo</Label>
                <Input id="nombre" value={form.nombre} onChange={(e) => setForm({ ...form, nombre: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="codigo">Código estudiantil</Label>
                <Input id="codigo" value={form.codigo} onChange={(e) => setForm({ ...form, codigo: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="correo">Correo institucional</Label>
                <Input id="correo" type="email" placeholder="tu.correo@uceva.edu.co" value={form.correo} onChange={(e) => setForm({ ...form, correo: e.target.value })} required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="password">Contraseña</Label>
                <Input id="password" type="password" placeholder="Mínimo 6 caracteres" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required minLength={6} />
              </div>
              <div className="space-y-2">
                <Label>Facultad</Label>
                <Select value={form.facultad_id} onValueChange={(v) => setForm({ ...form, facultad_id: v, carrera_id: "" })}>
                  <SelectTrigger><SelectValue placeholder="Selecciona facultad" /></SelectTrigger>
                  <SelectContent>
                    {facultades.map((f) => (
                      <SelectItem key={f.id} value={f.id}>{f.nombre}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Carrera</Label>
                <Select value={form.carrera_id} onValueChange={(v) => setForm({ ...form, carrera_id: v })} disabled={!form.facultad_id}>
                  <SelectTrigger><SelectValue placeholder={form.facultad_id ? "Selecciona carrera" : "Primero selecciona facultad"} /></SelectTrigger>
                  <SelectContent>
                    {filteredCarreras.map((c) => (
                      <SelectItem key={c.id} value={c.id}>{c.nombre}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="semestre">Semestre</Label>
                <Select value={form.semestre} onValueChange={(v) => setForm({ ...form, semestre: v })}>
                  <SelectTrigger><SelectValue placeholder="Selecciona semestre" /></SelectTrigger>
                  <SelectContent>
                    {[1,2,3,4,5,6,7,8,9,10].map((s) => (
                      <SelectItem key={s} value={s.toString()}>Semestre {s}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <Button type="submit" className="w-full gap-2" disabled={submitting}>
                {submitting ? <Loader2 className="h-4 w-4 animate-spin" /> : <UserPlus className="h-4 w-4" />}
                Registrarse
              </Button>
            </form>
            <p className="mt-4 text-center text-sm text-muted-foreground">
              ¿Ya tienes cuenta?{" "}
              <Link to="/login" className="text-primary font-medium hover:underline">Inicia sesión</Link>
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
