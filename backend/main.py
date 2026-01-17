from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timedelta
import os
import json
import requests
from collections import defaultdict, Counter
import numpy as np
from typing import List, Dict, Any
import re

app = Flask(__name__)
CORS(app)

# ============================================
# CONFIGURATION
# ============================================
import os

GROQ_API_KEY = os.getenv("GROQ_API_KEY")
TAVILY_API_KEY = os.getenv("TAVILY_API_KEY")


GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
TAVILY_API_URL = "https://api.tavily.com/search"

# ============================================
# IN-MEMORY DATA STORAGE (Real-time tracking)
# ============================================
patients_queue = []  # Active patient queue
doctor_workload = defaultdict(lambda: {
    'tasks': [],
    'hours_worked': 0,
    'patients_seen': 0,
    'stress_level': 0,
    'last_break': None,
    'specialization': 'general'
})
shift_handovers = []
historical_patient_flow = []
staff_members = {}
voice_notes = []

# Sample data initialization
def initialize_sample_data():
    """Initialize with sample data for demonstration"""
    global patients_queue, doctor_workload
    
    # Sample patients
    if len(patients_queue) == 0:
        patients_queue.extend([
            {
                'id': 1,
                'patient_name': 'John Doe',
                'symptoms': 'Severe chest pain, shortness of breath',
                'age': 65,
                'vital_signs': {'bp': '160/100', 'pulse': 110},
                'priority': 'CRITICAL',
                'triage_assessment': 'Critical - Immediate attention required',
                'arrival_time': datetime.now().isoformat(),
                'status': 'waiting'
            },
            {
                'id': 2,
                'patient_name': 'Sarah Johnson',
                'symptoms': 'High fever, severe headache',
                'age': 28,
                'vital_signs': {'temp': '103°F', 'pulse': 95},
                'priority': 'HIGH',
                'triage_assessment': 'High priority - Quick assessment needed',
                'arrival_time': datetime.now().isoformat(),
                'status': 'waiting'
            },
            {
                'id': 3,
                'patient_name': 'Mike Brown',
                'symptoms': 'Minor cut on hand',
                'age': 35,
                'vital_signs': {'bp': '120/80', 'pulse': 72},
                'priority': 'LOW',
                'triage_assessment': 'Low priority - Can wait',
                'arrival_time': datetime.now().isoformat(),
                'status': 'waiting'
            }
        ])
    
    # Sample doctor data
    doctor_workload['dr_smith']['hours_worked'] = 6
    doctor_workload['dr_smith']['patients_seen'] = 12
    doctor_workload['dr_smith']['stress_level'] = 7
    doctor_workload['dr_smith']['last_break'] = (datetime.now() - timedelta(hours=3)).isoformat()

# Initialize on startup
initialize_sample_data()

# ============================================
# ADVANCED RAG SYSTEM
# ============================================
class AdvancedRAGSystem:
    def __init__(self):
        self.knowledge_base = []
        self.embeddings_cache = {}
        
    def add_document(self, doc_id: str, content: str, metadata: dict):
        """Add document to knowledge base"""
        self.knowledge_base.append({
            'id': doc_id,
            'content': content,
            'metadata': metadata,
            'timestamp': datetime.now().isoformat()
        })
    
    def semantic_search(self, query: str, top_k: int = 5) -> List[Dict]:
        """Simple keyword-based semantic search"""
        query_terms = set(query.lower().split())
        scored_docs = []
        
        for doc in self.knowledge_base:
            content_terms = set(doc['content'].lower().split())
            score = len(query_terms.intersection(content_terms))
            if score > 0:
                scored_docs.append((score, doc))
        
        scored_docs.sort(reverse=True, key=lambda x: x[0])
        return [doc for _, doc in scored_docs[:top_k]]
    
    def retrieve_and_generate(self, query: str, context_type: str = "general") -> str:
        """RAG: Retrieve relevant docs and generate response"""
        relevant_docs = self.semantic_search(query)
        
        context = "\n\n".join([
            f"Document {i+1}: {doc['content']}"
            for i, doc in enumerate(relevant_docs)
        ])
        
        prompt = f"""Based on the following medical context, answer the query.

Context:
{context}

Query: {query}

Provide a detailed, accurate response based on the context provided."""

        return self.generate_with_llm(prompt)
    
    def generate_with_llm(self, prompt: str, model: str = "llama-3.3-70b-versatile") -> str:
        """Generate response using Groq LLM"""
        try:
            headers = {
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json"
            }
            
            payload = {
                "model": model,
                "messages": [{"role": "user", "content": prompt}],
                "temperature": 0.7,
                "max_tokens": 1500
            }
            
            response = requests.post(GROQ_API_URL, headers=headers, json=payload, timeout=30)
            response.raise_for_status()
            
            return response.json()['choices'][0]['message']['content']
        except Exception as e:
            print(f"LLM Error: {str(e)}")
            return f"AI analysis temporarily unavailable. Error: {str(e)}"
    
    def web_search(self, query: str) -> List[Dict]:
        """Search web using Tavily API for real-time medical information"""
        try:
            payload = {
                "api_key": TAVILY_API_KEY,
                "query": query,
                "search_depth": "advanced",
                "max_results": 5
            }
            
            response = requests.post(TAVILY_API_URL, json=payload, timeout=15)
            response.raise_for_status()
            
            results = response.json().get('results', [])
            
            # Add to knowledge base
            for idx, result in enumerate(results):
                self.add_document(
                    doc_id=f"web_{datetime.now().timestamp()}_{idx}",
                    content=f"{result.get('title', '')}\n{result.get('content', '')}",
                    metadata={'source': 'web', 'url': result.get('url', '')}
                )
            
            return results
        except Exception as e:
            print(f"Web search error: {str(e)}")
            return []

# Initialize RAG system
rag_system = AdvancedRAGSystem()

# ============================================
# FEATURE 1: AI TRIAGE ASSISTANT
# ============================================
@app.route('/api/triage', methods=['POST'])
def ai_triage():
    """AI-powered symptom analysis with RAG for prioritization"""
    try:
        data = request.json
        patient_name = data.get('patient_name', 'Unknown')
        symptoms = data.get('symptoms', '')
        age = data.get('age', 0)
        vital_signs = data.get('vital_signs', {})
        
        if not symptoms:
            return jsonify({
                'success': False,
                'error': 'Symptoms are required'
            }), 400
        
        # Simplified triage logic with rule-based priority
        priority = "MEDIUM"
        
        # Critical keywords
        critical_keywords = ['chest pain', 'difficulty breathing', 'unconscious', 'severe bleeding', 
                            'stroke', 'heart attack', 'not breathing']
        high_keywords = ['high fever', 'severe pain', 'vomiting', 'broken bone', 'deep cut']
        
        symptoms_lower = symptoms.lower()
        
        if any(keyword in symptoms_lower for keyword in critical_keywords):
            priority = "CRITICAL"
        elif any(keyword in symptoms_lower for keyword in high_keywords):
            priority = "HIGH"
        elif 'minor' in symptoms_lower or 'small' in symptoms_lower:
            priority = "LOW"
        
        # Generate AI assessment
        triage_prompt = f"""You are an expert medical triage AI. Analyze this patient briefly:

Patient: {patient_name}, Age: {age}
Symptoms: {symptoms}
Vital Signs: {json.dumps(vital_signs)}

Provide a brief triage assessment (2-3 sentences) with recommended actions."""

        ai_assessment = rag_system.generate_with_llm(triage_prompt)
        
        # Add to patient queue
        patient_entry = {
            'id': len(patients_queue) + 1,
            'patient_name': patient_name,
            'symptoms': symptoms,
            'age': age,
            'vital_signs': vital_signs,
            'priority': priority,
            'triage_assessment': ai_assessment,
            'arrival_time': datetime.now().isoformat(),
            'status': 'waiting'
        }
        
        patients_queue.append(patient_entry)
        
        # Sort queue by priority
        priority_order = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3}
        patients_queue.sort(key=lambda x: priority_order.get(x['priority'], 4))
        
        # Track patient flow
        historical_patient_flow.append({
            'timestamp': datetime.now().isoformat(),
            'priority': priority,
            'hour': datetime.now().hour
        })
        
        return jsonify({
            'success': True,
            'patient': patient_entry,
            'queue_position': next((i for i, p in enumerate(patients_queue) if p['id'] == patient_entry['id']), 0) + 1,
            'total_in_queue': len(patients_queue)
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================
# FEATURE 2: SMART SHIFT HANDOVER
# ============================================
@app.route('/api/shift-handover', methods=['POST'])
def smart_shift_handover():
    """Auto-generate comprehensive shift handover report"""
    try:
        data = request.json
        doctor_id = data.get('doctor_id', 'unknown')
        shift_end_time = data.get('shift_end_time', datetime.now().isoformat())
        
        # Gather all relevant data
        doctor_data = doctor_workload[doctor_id]
        active_patients = [p for p in patients_queue if p.get('status') in ['waiting', 'in_progress']]
        
        handover_prompt = f"""Generate a concise shift handover report for Dr. {doctor_id}.

Current Time: {shift_end_time}

Shift Summary:
- Hours Worked: {doctor_data['hours_worked']}
- Patients Seen: {doctor_data['patients_seen']}
- Stress Level: {doctor_data['stress_level']}/10

Active Patients: {len(active_patients)}

Critical Information:
{json.dumps(active_patients[:3], indent=2) if active_patients else 'No active patients'}

Generate a structured handover with:
1. Critical patients requiring immediate attention
2. Key pending items
3. Important notes for incoming doctor"""

        handover_report = rag_system.generate_with_llm(handover_prompt)
        
        handover_entry = {
            'id': len(shift_handovers) + 1,
            'doctor_id': doctor_id,
            'shift_end_time': shift_end_time,
            'report': handover_report,
            'active_patients_count': len(active_patients),
            'critical_count': len([p for p in active_patients if p.get('priority') == 'CRITICAL']),
            'generated_at': datetime.now().isoformat()
        }
        
        shift_handovers.append(handover_entry)
        
        return jsonify({
            'success': True,
            'handover': handover_entry
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================
# FEATURE 3: BURNOUT RISK PREDICTOR
# ============================================
@app.route('/api/burnout-analysis', methods=['POST'])
def burnout_risk_predictor():
    """Analyze workload patterns to predict burnout risk"""
    try:
        data = request.json
        doctor_id = data.get('doctor_id', 'unknown')
        
        doctor_data = doctor_workload[doctor_id]
        
        # Calculate burnout indicators
        hours_worked = doctor_data['hours_worked']
        patients_seen = doctor_data['patients_seen']
        stress_level = doctor_data['stress_level']
        tasks_pending = len([t for t in doctor_data['tasks'] if t.get('status') == 'pending'])
        
        # Check break patterns
        last_break = doctor_data.get('last_break')
        hours_since_break = 0
        if last_break:
            last_break_time = datetime.fromisoformat(last_break)
            hours_since_break = (datetime.now() - last_break_time).seconds / 3600
        
        # Calculate risk level
        risk_score = 0
        if hours_worked > 10:
            risk_score += 30
        if stress_level > 7:
            risk_score += 30
        if hours_since_break > 4:
            risk_score += 20
        if patients_seen > 15:
            risk_score += 20
        
        if risk_score >= 70:
            risk_level = "CRITICAL"
        elif risk_score >= 50:
            risk_level = "HIGH"
        elif risk_score >= 30:
            risk_level = "MODERATE"
        else:
            risk_level = "LOW"
        
        burnout_prompt = f"""Analyze burnout risk for Dr. {doctor_id}:

Metrics:
- Hours: {hours_worked}, Patients: {patients_seen}
- Stress: {stress_level}/10, Hours since break: {hours_since_break:.1f}

Risk Score: {risk_score}/100

Provide brief recommendations (3-4 points) for managing workload and preventing burnout."""

        analysis = rag_system.generate_with_llm(burnout_prompt)
        
        result = {
            'doctor_id': doctor_id,
            'burnout_risk_level': risk_level,
            'risk_score': risk_score,
            'analysis': analysis,
            'metrics': {
                'hours_worked': hours_worked,
                'patients_seen': patients_seen,
                'stress_level': stress_level,
                'tasks_pending': tasks_pending,
                'hours_since_break': round(hours_since_break, 2)
            },
            'analyzed_at': datetime.now().isoformat()
        }
        
        return jsonify({
            'success': True,
            'burnout_analysis': result
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================
# FEATURE 4: VOICE-TO-DOCUMENTATION
# ============================================
@app.route('/api/voice-to-doc', methods=['POST'])
def voice_to_documentation():
    """Convert doctor voice notes to structured medical records"""
    try:
        data = request.json
        doctor_id = data.get('doctor_id', 'unknown')
        patient_id = data.get('patient_id', 'unknown')
        voice_transcript = data.get('voice_transcript', '')
        
        if not voice_transcript:
            return jsonify({
                'success': False,
                'error': 'Voice transcript is required'
            }), 400
        
        documentation_prompt = f"""Convert this doctor's note into a structured SOAP format medical record:

Doctor: {doctor_id}
Patient ID: {patient_id}

Notes: {voice_transcript}

Generate a professional medical record with:
- Subjective: Patient's complaint
- Objective: Physical findings
- Assessment: Diagnosis
- Plan: Treatment plan

Keep it concise and professional."""

        structured_doc = rag_system.generate_with_llm(documentation_prompt)
        
        voice_note_entry = {
            'id': len(voice_notes) + 1,
            'doctor_id': doctor_id,
            'patient_id': patient_id,
            'original_transcript': voice_transcript,
            'structured_documentation': structured_doc,
            'created_at': datetime.now().isoformat()
        }
        
        voice_notes.append(voice_note_entry)
        
        # Add to RAG knowledge base
        rag_system.add_document(
            doc_id=f"medical_record_{voice_note_entry['id']}",
            content=structured_doc,
            metadata={'type': 'medical_record', 'patient_id': patient_id}
        )
        
        return jsonify({
            'success': True,
            'documentation': voice_note_entry
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

# ============================================
# ADDITIONAL HELPER ENDPOINTS
# ============================================

@app.route('/api/doctor/update-workload', methods=['POST'])
def update_doctor_workload():
    """Update doctor workload metrics in real-time"""
    try:
        data = request.json
        doctor_id = data.get('doctor_id', 'unknown')
        
        if 'hours_worked' in data:
            doctor_workload[doctor_id]['hours_worked'] = data['hours_worked']
        if 'patients_seen' in data:
            doctor_workload[doctor_id]['patients_seen'] = data['patients_seen']
        if 'stress_level' in data:
            doctor_workload[doctor_id]['stress_level'] = data['stress_level']
        if 'last_break' in data:
            doctor_workload[doctor_id]['last_break'] = data['last_break']
        if 'specialization' in data:
            doctor_workload[doctor_id]['specialization'] = data['specialization']
        
        return jsonify({
            'success': True,
            'doctor_id': doctor_id,
            'updated_workload': dict(doctor_workload[doctor_id])
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/patient-queue', methods=['GET'])
def get_patient_queue():
    """Get current patient queue"""
    try:
        return jsonify({
            'success': True,
            'queue': patients_queue,
            'total_patients': len(patients_queue),
            'critical_count': len([p for p in patients_queue if p.get('priority') == 'CRITICAL']),
            'waiting_count': len([p for p in patients_queue if p.get('status') == 'waiting'])
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/patient/<int:patient_id>/status', methods=['PUT'])
def update_patient_status(patient_id):
    """Update patient status"""
    try:
        data = request.json
        new_status = data.get('status')
        
        for patient in patients_queue:
            if patient['id'] == patient_id:
                patient['status'] = new_status
                if new_status == 'completed':
                    patient['completion_time'] = datetime.now().isoformat()
                return jsonify({'success': True, 'patient': patient})
        
        return jsonify({'success': False, 'error': 'Patient not found'}), 404
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/stats', methods=['GET'])
def get_system_stats():
    """Get overall system statistics"""
    try:
        return jsonify({
            'success': True,
            'stats': {
                'total_patients_today': len(patients_queue),
                'patients_in_queue': len([p for p in patients_queue if p['status'] == 'waiting']),
                'active_doctors': len(doctor_workload),
                'total_tasks': sum(len(d['tasks']) for d in doctor_workload.values()),
                'handovers_generated': len(shift_handovers),
                'voice_notes_processed': len(voice_notes),
                'knowledge_base_documents': len(rag_system.knowledge_base),
                'historical_data_points': len(historical_patient_flow),
                'critical_patients': len([p for p in patients_queue if p.get('priority') == 'CRITICAL'])
            }
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
    # ============================================
# FEATURE 5: INTELLIGENT CHATBOT WITH RAG
# ============================================
@app.route('/api/chatbot', methods=['POST'])
def intelligent_chatbot():
    """AI chatbot that answers questions about patients using RAG"""
    try:
        data = request.json
        query = data.get('query', '')
        patient_id = data.get('patient_id', None)
        
        if not query:
            return jsonify({
                'success': False,
                'error': 'Query is required'
            }), 400
        
        # If patient_id is provided, retrieve specific patient context
        context_documents = []
        
        if patient_id:
            # Get patient from queue
            patient = next((p for p in patients_queue if str(p.get('id')) == str(patient_id) or 
                          p.get('patient_name', '').lower() == patient_id.lower()), None)
            
            if patient:
                context_documents.append({
                    'content': f"""Patient Information:
Name: {patient.get('patient_name')}
Age: {patient.get('age')}
Symptoms: {patient.get('symptoms')}
Priority: {patient.get('priority')}
Vital Signs: {json.dumps(patient.get('vital_signs', {}))}
Status: {patient.get('status')}
Triage Assessment: {patient.get('triage_assessment', 'Not available')}
Arrival Time: {patient.get('arrival_time')}""",
                    'metadata': {'type': 'patient_record', 'patient_id': patient_id}
                })
            
            # Get medical records from voice notes
            patient_notes = [note for note in voice_notes 
                           if str(note.get('patient_id')) == str(patient_id)]
            
            for note in patient_notes:
                context_documents.append({
                    'content': f"""Medical Documentation:
{note.get('structured_documentation', note.get('original_transcript', ''))}
Created: {note.get('created_at')}""",
                    'metadata': {'type': 'medical_record', 'patient_id': patient_id}
                })
        
        # Search RAG knowledge base
        rag_results = rag_system.semantic_search(query, top_k=3)
        context_documents.extend(rag_results)
        
        # If no specific context found, get general patient queue info
        if not context_documents:
            queue_summary = f"""Current Patient Queue Summary:
Total Patients: {len(patients_queue)}
Critical: {len([p for p in patients_queue if p.get('priority') == 'CRITICAL'])}
High: {len([p for p in patients_queue if p.get('priority') == 'HIGH'])}
Waiting: {len([p for p in patients_queue if p.get('status') == 'waiting'])}"""
            
            context_documents.append({
                'content': queue_summary,
                'metadata': {'type': 'queue_summary'}
            })
        
        # Build context from documents
        context = "\n\n---\n\n".join([
            f"Document {i+1}:\n{doc.get('content', '')}"
            for i, doc in enumerate(context_documents)
        ])
        
        # Create chatbot prompt
        chatbot_prompt = f"""You are an intelligent medical assistant AI helping doctors and staff.
You have access to patient records, medical documentation, and hospital data.

Context Information:
{context}

User Question: {query}

Instructions:
- Answer based ONLY on the context provided above
- Be concise and accurate
- If asked about a specific patient, provide their details
- If information is not in context, say "I don't have that information in the current records"
- Use medical terminology appropriately
- Be helpful and professional

Answer:"""

        response_text = rag_system.generate_with_llm(chatbot_prompt)
        
        return jsonify({
            'success': True,
            'response': response_text,
            'context_used': len(context_documents),
            'patient_specific': patient_id is not None
        })
    
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@app.route('/api/chatbot/suggestions', methods=['GET'])
def chatbot_suggestions():
    """Get suggested questions for the chatbot"""
    suggestions = [
        "What is the current patient queue status?",
        "Who are the critical patients?",
        "Show me patient details",
        "What's the triage assessment?",
        "List all waiting patients",
        "Any high priority cases?",
        "Patient vital signs information",
        "Recent medical documentation"
    ]
    
    return jsonify({
        'success': True,
        'suggestions': suggestions
    })

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'Doctor Workload Optimization System',
        'version': '2.0'
    })

# ============================================
# MAIN
# ============================================
if __name__ == '__main__':
    print("=" * 60)
    print("Doctor Workload Optimization System v2.0")
    print("Advanced RAG-Powered Medical Management")
    print("=" * 60)
    print("\nSample data initialized!")
    print("Starting server on http://0.0.0.0:5000")
    print("\nIMPORTANT: For mobile testing, use your computer's IP address")
    print("Find it with: ipconfig (Windows) or ifconfig (Mac/Linux)")
    print("=" * 60)
    
    # Run on all interfaces so it's accessible from mobile devices
    app.run(debug=True, host='0.0.0.0', port=5000)