import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/hooks/useAuth";
import { BookOpen, GraduationCap, User, XCircle, ChevronRight, X } from "lucide-react";

const steps = [
  {
    icon: BookOpen,
    title: "Catálogo de Materias",
    description: "Aquí puedes consultar todas las materias disponibles filtradas por carrera y semestre. Inscríbete directamente desde la tabla.",
  },
  {
    icon: GraduationCap,
    title: "Mis Materias",
    description: "Revisa tus materias inscritas, controla tus créditos totales y consulta tu carga académica.",
  },
  {
    icon: XCircle,
    title: "Cancelar Materias",
    description: "En la sección 'Cancelar Materias' puedes eliminar materias que ya no necesites. Los cupos se liberan automáticamente.",
  },
  {
    icon: User,
    title: "Tu Perfil",
    description: "Consulta tus datos personales y repite este tutorial cuando quieras desde tu perfil.",
  },
];

export default function OnboardingTutorial() {
  const { profile, markTutorialSeen } = useAuth();
  const [step, setStep] = useState(0);

  // Don't show if profile not loaded or tutorial already seen
  if (!profile || profile.tutorial_visto) return null;

  const finish = async () => {
    await markTutorialSeen();
  };

  const current = steps[step];
  const Icon = current.icon;

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-[60] bg-foreground/50 backdrop-blur-sm flex items-center justify-center p-4"
      >
        <motion.div
          key={step}
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: -20 }}
          className="bg-card rounded-2xl shadow-2xl max-w-sm w-full p-6 relative"
        >
          <button onClick={finish} className="absolute top-4 right-4 text-muted-foreground hover:text-foreground">
            <X className="h-5 w-5" />
          </button>

          <div className="flex flex-col items-center text-center">
            <div className="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center mb-4">
              <Icon className="h-8 w-8 text-primary" />
            </div>
            <h3 className="font-display text-lg font-bold text-foreground mb-2">{current.title}</h3>
            <p className="text-sm text-muted-foreground leading-relaxed">{current.description}</p>

            <div className="flex items-center gap-1.5 my-5">
              {steps.map((_, i) => (
                <div key={i} className={`h-1.5 rounded-full transition-all ${i === step ? "w-6 bg-primary" : "w-1.5 bg-border"}`} />
              ))}
            </div>

            <div className="flex gap-3 w-full">
              <Button variant="outline" className="flex-1" onClick={finish}>
                Saltar
              </Button>
              <Button
                className="flex-1 gap-1"
                onClick={() => (step < steps.length - 1 ? setStep(step + 1) : finish())}
              >
                {step < steps.length - 1 ? "Siguiente" : "¡Empezar!"}
                <ChevronRight className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </motion.div>
      </motion.div>
    </AnimatePresence>
  );
}
