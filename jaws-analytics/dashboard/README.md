# JAWS Analytics Dashboard

React-based dashboard for viewing RALPH-JAWS build analytics.

## Features

- **Project Navigation**: Browse all analyzed projects from sidebar
- **Responsive Design**: Works on mobile, tablet, and desktop
- **View Modes**: Switch between Client and Technical views
- **Supabase Integration**: Real-time data from PostgreSQL database

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment Variables

Copy `.env.example` to `.env` and fill in your Supabase credentials:

```bash
cp .env.example .env
```

Edit `.env`:
```
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

### 3. Run Development Server

```bash
npm run dev
```

The dashboard will be available at `http://localhost:3000`

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run linting (placeholder)
- `npm run typecheck` - Run type checking (placeholder)

## Project Structure

```
dashboard/
├── src/
│   ├── components/
│   │   ├── Sidebar.jsx       # Navigation sidebar
│   │   └── Header.jsx         # Header with view toggle
│   ├── lib/
│   │   └── supabase.js        # Supabase client
│   ├── App.jsx                # Main app component
│   ├── main.jsx               # React entry point
│   └── index.css              # Global styles
├── public/                    # Static assets
├── index.html                 # HTML entry point
├── vite.config.js             # Vite configuration
├── tailwind.config.js         # Tailwind configuration
└── package.json               # Dependencies
```

## Technology Stack

- **React 19** - UI framework
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Utility-first CSS
- **Supabase** - Database and backend
- **Recharts** - Charts and visualizations
- **Lucide React** - Icon library

## Components

### Sidebar
- Fetches projects from Supabase `jaws_builds` table
- Mobile-responsive with hamburger menu
- Shows project names and client names
- Active project highlighting

### Header
- Logo and branding
- View toggle (Client/Technical)
- Persists preference to localStorage

## Responsive Breakpoints

- **Mobile**: < 768px (hamburger menu)
- **Desktop**: >= 768px (persistent sidebar)

## Next Steps

Future user stories will add:
- Stats cards (US-014)
- Architecture diagrams (US-015)
- Workflow breakdown tables (US-016)
- Token usage charts (US-017)
- Build timelines (US-018)
- PDF export (US-020)

## Troubleshooting

**Dashboard shows "No projects yet"**
- Verify Supabase credentials in `.env`
- Check that `jaws_builds` table exists and has data
- Open browser console for error messages

**Vite dev server won't start**
- Ensure Node.js 18+ is installed
- Delete `node_modules` and run `npm install` again
- Check that port 3000 is not already in use
