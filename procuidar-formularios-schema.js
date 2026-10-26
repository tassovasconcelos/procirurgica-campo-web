export default {
  "schemaVersion": "1.1.0-homologacao",
  "program": {
    "name": "ProCuidar",
    "description": "Programa de Cuidado Continuado do Grupo Prohospital"
  },
  "status": "rascunho_para_revisao",
  "sourceReading": "Texto parcialmente extraído das imagens; não foi possível inspecionar todos os detalhes visuais. Não representa transcrição integral.",
  "productionEnabled": false,
  "forms": [
    {
      "id": "confortcath",
      "title": "Avaliação e teste — ConfortCath",
      "sources": [
        "image(1).png",
        "image(2).png"
      ],
      "fields": [
        {
          "id": "registro_profissional",
          "label": "Conselho / registro profissional",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "produto_referencia",
          "label": "Produto / referência",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "lote",
          "label": "Lote",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_inicio",
          "label": "Início do teste",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_retorno",
          "label": "Retorno previsto",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "informacoes_medicas",
          "label": "Informações médicas",
          "type": "textarea",
          "source": "image(1).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "destreza",
          "label": "Destreza manual",
          "type": "select",
          "source": "image(1).png",
          "origin": "imagem_leitura_parcial",
          "options": [
            "Preservada",
            "Reduzida",
            "Nula"
          ]
        },
        {
          "id": "resultado_medico",
          "label": "Resultado médico",
          "type": "textarea",
          "source": "image(2).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "origem_lesao",
          "label": "Origem da lesão neurológica",
          "type": "textarea",
          "source": "image(2).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "nocturia",
          "label": "Levanta à noite para urinar?",
          "type": "select",
          "source": "image(2).png",
          "origin": "imagem_leitura_parcial",
          "options": [
            "Sim",
            "Não"
          ]
        },
        {
          "id": "historico_itu",
          "label": "História de infecção urinária",
          "type": "textarea",
          "source": "image(2).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "indicacao",
          "label": "Indicação do ConfortCath",
          "type": "textarea",
          "source": "image(2).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "cateteres_dia",
          "label": "Cateteres por dia — conforme indicação registrada",
          "type": "number",
          "source": "image(2).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "modelo",
          "label": "Modelo do ConfortCath — transcrição livre da referência",
          "type": "text",
          "source": "image(2).png",
          "origin": "imagem_leitura_parcial"
        }
      ],
      "pending": [
        "Diagnósticos e alternativas de informações médicas ilegíveis na extração.",
        "Confirmar alternativas da origem da lesão e do histórico de infecção.",
        "Confirmar tabela de modelos, calibres e comprimentos. Não cadastrada por inferência."
      ]
    },
    {
      "id": "atendimento_ostomia",
      "title": "Atendimento e acompanhamento — Ostomia",
      "sources": [
        "image(3).png",
        "image(4).png"
      ],
      "fields": [
        {
          "id": "registro_profissional",
          "label": "Conselho / registro profissional",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "produto_referencia",
          "label": "Produto / referência",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "lote",
          "label": "Lote",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_inicio",
          "label": "Início do teste",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_retorno",
          "label": "Retorno previsto",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "inicio_bolsa",
          "label": "Desde quando usa a bolsa?",
          "type": "text",
          "source": "image(3).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "medico",
          "label": "Nome do médico",
          "type": "text",
          "source": "image(3).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "local_atendimento",
          "label": "Local de atendimento",
          "type": "text",
          "source": "image(3).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "derivacao",
          "label": "Tipo de derivação",
          "type": "text",
          "source": "image(3).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "motivo",
          "label": "Motivo",
          "type": "textarea",
          "source": "image(3).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "acessorios",
          "label": "Acessórios",
          "type": "textarea",
          "source": "image(4).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "encaminhamento",
          "label": "Encaminhamento",
          "type": "textarea",
          "source": "image(4).png",
          "origin": "imagem_leitura_parcial"
        }
      ],
      "pending": [
        "Confirmar todas as alternativas de tipo de derivação; campo livre provisório.",
        "Confirmar campos e alternativas de hospital/local de atendimento.",
        "Revisar as demais seções da imagem(4); extração insuficiente."
      ]
    },
    {
      "id": "avaliacao_coletor",
      "title": "Avaliação técnica — Equipamento coletor",
      "sources": [
        "image(5).png"
      ],
      "fields": [
        {
          "id": "registro_profissional",
          "label": "Conselho / registro profissional",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "produto_referencia",
          "label": "Produto / referência",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "lote",
          "label": "Lote",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_inicio",
          "label": "Início do teste",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_retorno",
          "label": "Retorno previsto",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "angulo",
          "label": "Ângulo de drenagem — registrar avaliação",
          "type": "text",
          "source": "image(5).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "abdomen",
          "label": "Tipo de abdômen",
          "type": "text",
          "source": "image(5).png",
          "origin": "imagem_leitura_parcial"
        },
        {
          "id": "equipamento",
          "label": "Equipamento coletor",
          "type": "select",
          "source": "image(5).png",
          "origin": "imagem_leitura_parcial",
          "options": [
            "1 peça",
            "2 peças"
          ]
        },
        {
          "id": "observacoes",
          "label": "Observações",
          "type": "textarea",
          "source": "image(5).png",
          "origin": "imagem_leitura_parcial"
        }
      ],
      "pending": [
        "Confirmar a escala de ângulo de drenagem e sua unidade.",
        "Confirmar os desenhos e alternativas de tipo de abdômen.",
        "Confirmar associação de cada linha da tabela ao equipamento."
      ]
    },
    {
      "id": "conclusao_teste",
      "title": "Conclusão do teste e homologação",
      "sources": [],
      "fields": [
        {
          "id": "registro_profissional",
          "label": "Conselho / registro profissional",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "produto_referencia",
          "label": "Produto / referência",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "lote",
          "label": "Lote",
          "type": "text",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_inicio",
          "label": "Início do teste",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "data_retorno",
          "label": "Retorno previsto",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "avaliado_em",
          "label": "Data da avaliação",
          "type": "date",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "resultado",
          "label": "Resultado registrado pelo responsável",
          "type": "select",
          "origin": "complemento_operacional_proposto",
          "options": [
            "Em acompanhamento",
            "Aprovado",
            "Aprovado com ressalvas",
            "Reprovado",
            "Interrompido",
            "Inconclusivo"
          ]
        },
        {
          "id": "evidencias",
          "label": "Evidências e justificativa",
          "type": "textarea",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "intercorrencias",
          "label": "Intercorrências e medidas registradas",
          "type": "textarea",
          "origin": "complemento_operacional_proposto"
        },
        {
          "id": "proximos_passos",
          "label": "Próximos passos e responsável",
          "type": "textarea",
          "origin": "complemento_operacional_proposto"
        }
      ],
      "pending": [
        "Formulário complementar proposto; não transcrito das imagens.",
        "Critérios de aprovação e responsáveis habilitados precisam de validação institucional.",
        "Nenhuma homologação ou indicação clínica é gerada automaticamente."
      ]
    }
  ]
};
