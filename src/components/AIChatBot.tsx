import { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/hooks/useAuth";
import { MessageCircle, X, Send, Bot } from "lucide-react";

interface Message {
  role: "user" | "assistant";
  content: string;
}

const appKnowledge: Record<string, string> = {
  inscribir: "Para inscribir materias, ve al **Catálogo de Materias** desde el menú o dashboard. Filtra por carrera y semestre, y haz clic en 'Inscribir' en la materia deseada.",
  cancelar: "Para cancelar una materia, ve a **Cancelar Materias** desde el menú o dashboard. Haz clic en el botón 'Cancelar' junto a la materia que deseas eliminar. El cupo se libera automáticamente.",
  creditos: "El máximo de créditos permitidos por semestre es **21**. Puedes ver tus créditos actuales en el dashboard o en 'Mis Materias'.",
  cupos: "Los cupos disponibles se muestran en la columna 'Cupos' del catálogo. Si una materia muestra 0 cupos, aparecerá como 'Sin cupos'.",
  perfil: "En la sección **Perfil** puedes ver tus datos personales, la cantidad de materias inscritas y tus créditos. También puedes repetir el tutorial desde ahí.",
  horario: "Los horarios se muestran en la tabla del catálogo. El sistema valida automáticamente que no haya cruces de horario al inscribir.",
  registro: "Para registrarte necesitas: nombre, código estudiantil, correo @uceva.edu.co, contraseña (mín. 6 caracteres), carrera y semestre.",
  catalogo: "El catálogo muestra todas las materias disponibles. Puedes filtrar por **carrera** y **semestre** usando los selectores en la parte superior.",
  tutorial: "Puedes repetir el tutorial de bienvenida desde tu **Perfil**, haciendo clic en 'Repetir Tutorial'.",
  materias: "Tus materias inscritas se encuentran en la sección **Mis Materias**, accesible desde el menú de navegación o el dashboard.",
};

const defaultMessage: Message = { role: "assistant", content: "¡Hola! 👋 Soy tu asistente de UniControl. ¿En qué puedo ayudarte?" };

function getResponse(input: string): string {
  const lower = input.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");

  for (const [key, value] of Object.entries(appKnowledge)) {
    if (lower.includes(key)) return value;
  }

  if (lower.includes("ayuda") || lower.includes("help") || lower.includes("que puedo hacer")) {
    return "Puedo ayudarte con:\n- Cómo **inscribir** materias\n- Cómo **cancelar** materias\n- Información sobre **créditos**\n- **Cupos** disponibles\n- Tu **perfil** y datos\n- El **catálogo** de materias\n- **Horarios** y cruces";
  }

  if (lower.includes("hola") || lower.includes("hi") || lower.includes("buenas")) {
    return "¡Hola! 👋 Soy el asistente de **UCEVA UniControl**. ¿En qué puedo ayudarte? Pregúntame sobre inscripciones, materias, créditos o cualquier función de la app.";
  }

  return "Solo puedo responder preguntas sobre **UCEVA UniControl**. Pregúntame sobre inscripciones, materias, créditos, horarios o funciones de la app. Escribe **ayuda** para ver las opciones.";
}

export default function AIChatBot() {
  const { user } = useAuth();
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState<Message[]>([defaultMessage]);
  const [input, setInput] = useState("");
  const bottomRef = useRef<HTMLDivElement>(null);
  const prevUserIdRef = useRef<string | null>(null);

  // Reset chat when user changes
  useEffect(() => {
    const currentId = user?.id || null;
    if (prevUserIdRef.current !== null && prevUserIdRef.current !== currentId) {
      setMessages([defaultMessage]);
      setInput("");
    }
    prevUserIdRef.current = currentId;
  }, [user?.id]);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const send = () => {
    if (!input.trim()) return;
    const userMsg: Message = { role: "user", content: input.trim() };
    const response = getResponse(input.trim());
    setMessages((prev) => [...prev, userMsg, { role: "assistant", content: response }]);
    setInput("");
  };

  // Don't show chat if not logged in
  if (!user) return null;

  return (
    <>
      <motion.button
        onClick={() => setOpen(!open)}
        className="fixed bottom-6 right-6 z-50 w-14 h-14 rounded-full bg-primary text-primary-foreground shadow-lg flex items-center justify-center hover:scale-105 transition-transform"
        whileTap={{ scale: 0.95 }}
      >
        {open ? <X className="h-6 w-6" /> : <MessageCircle className="h-6 w-6" />}
      </motion.button>

      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            className="fixed bottom-24 right-6 z-50 w-[340px] max-h-[480px] bg-card rounded-2xl shadow-2xl border border-border flex flex-col overflow-hidden"
          >
            <div className="px-4 py-3 border-b border-border bg-primary/5 flex items-center gap-2">
              <Bot className="h-5 w-5 text-primary" />
              <span className="font-display font-semibold text-sm text-foreground">Asistente UniControl</span>
            </div>

            <div className="flex-1 overflow-y-auto px-4 py-3 space-y-3 min-h-[200px] max-h-[340px]">
              {messages.map((m, i) => (
                <div key={i} className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}>
                  <div
                    className={`max-w-[85%] px-3 py-2 rounded-xl text-sm whitespace-pre-wrap ${
                      m.role === "user"
                        ? "bg-primary text-primary-foreground rounded-br-sm"
                        : "bg-muted text-foreground rounded-bl-sm"
                    }`}
                  >
                    {m.content}
                  </div>
                </div>
              ))}
              <div ref={bottomRef} />
            </div>

            <div className="px-3 py-3 border-t border-border flex gap-2">
              <Input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && send()}
                placeholder="Escribe tu pregunta..."
                className="text-sm"
              />
              <Button size="icon" onClick={send} disabled={!input.trim()}>
                <Send className="h-4 w-4" />
              </Button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
