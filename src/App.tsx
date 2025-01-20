import { useEffect, useState } from 'react';
import { AlertDialog, AlertDialogPortal , AlertDialogContent, AlertDialogOverlay } from '@radix-ui/react-alert-dialog';
import { Calendar, Clock, MapPin, Users, Tag, DollarSign } from 'lucide-react';



const EventManagementApp = () => {
  const [events, setEvents] = useState<Event[]>([]);
  const [userProfile, setUserProfile] = useState(null);
  const [selectedEvent, setSelectedEvent] = useState<Event | null>(null);
  const [isCreatingEvent, setIsCreatingEvent] = useState(false);

  

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    try {
      const response = await fetch('/api/events');
      const data = await response.json();
      setEvents(data);
    } catch (error) {
      console.error('Error fetching events:', error);
    }
  };

  const registerForEvent = async (eventId: any) => {
    try {
      const response = await fetch(`/api/events/${eventId}/register`, { method: 'POST' });
      if (response.ok) {
        alert('Successfully registered for the event.');
        fetchEvents();
      } else {
        const errorData = await response.json();
        alert(`Error: ${errorData.message}`);
      }
    } catch (error) {
      console.error('Error registering for event:', error);
    }
  };

  const createEvent = async (event: {
      title: string; description: string; date: number; location: string; category: string; capacity: number; price: number; imageUrl: string; // Replace with real image handling
      registeredUsers: never[]; isActive: boolean;
    }) => {
    try {
      const response = await fetch('/api/events', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(event),
      });
      if (response.ok) {
        alert('Event created successfully.');
        setIsCreatingEvent(false);
        fetchEvents();
      } else {
        const errorData = await response.json();
        alert(`Error: ${errorData.message}`);
      }
    } catch (error) {
      console.error('Error creating event:', error);
    }
  };


  type Event = {
    id: string;
    creator: string;
    title: string;
    description: string;
    date: number;
    location: string;
    category: string;
    capacity: number;
    price: number;
    imageUrl: string;
    registeredUsers: string[];
    isActive: boolean;
    createdAt: number;
  };


  

  const EventCard = ({ event }: { event: Event }) => (
    <div className="bg-white rounded-lg shadow-md p-6 mb-4">
      <img src={event.imageUrl} alt={event.title} className="w-full h-48 object-cover rounded-md mb-4" />
      <h3 className="text-xl font-bold mb-2">{event.title}</h3>
      <p className="text-gray-600 mb-4">{event.description}</p>
      <div className="grid grid-cols-2 gap-4">
        <div className="flex items-center">
          <Calendar className="mr-2" size={16} />
          <span>{new Date(event.date).toLocaleDateString()}</span>
        </div>
        <div className="flex items-center">
          <MapPin className="mr-2" size={16} />
          <span>{event.location}</span>
        </div>
        <div className="flex items-center">
          <Tag className="mr-2" size={16} />
          <span>{event.category}</span>
        </div>
        <div className="flex items-center">
          <Users className="mr-2" size={16} />
          <span>{event.registeredUsers.length}/{event.capacity}</span>
        </div>
        <div className="flex items-center">
          <DollarSign className="mr-2" size={16} />
          <span>${event.price}</span>
        </div>
      </div>
      <div className="mt-4">
        <button
          onClick={() => setSelectedEvent(event)}
          className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          Register
        </button>
      </div>
    </div>
  );

  const CreateEventForm = () => {
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [date, setDate] = useState('');
    const [location, setLocation] = useState('');
    const [category, setCategory] = useState('');
    const [capacity, setCapacity] = useState(0);
    const [price, setPrice] = useState(0);

    const handleSubmit = (e: { preventDefault: () => void; }) => {
      e.preventDefault();
      createEvent({
        title,
        description,
        date: new Date(date).getTime(),
        location,
        category,
        capacity,
        price,
        imageUrl: '/api/placeholder/400/200', // Replace with real image handling
        registeredUsers: [],
        isActive: true,
      });
    };


    
    return (
      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-2xl font-bold mb-4">Create New Event</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Title</label>
            <input
              type="text"
              className="w-full p-2 border rounded"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Description</label>
            <textarea
              className="w-full p-2 border rounded"
              rows={3}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            ></textarea>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Date</label>
              <input
                type="date"
                className="w-full p-2 border rounded"
                value={date}
                onChange={(e) => setDate(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Location</label>
              <input
                type="text"
                className="w-full p-2 border rounded"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
              />
            </div>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">Category</label>
              <input
                type="text"
                className="w-full p-2 border rounded"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Capacity</label>
              <input
                type="number"
                className="w-full p-2 border rounded"
                value={capacity}
                onChange={(e) => setCapacity(parseInt(e.target.value))}
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">Price</label>
              <input
                type="number"
                className="w-full p-2 border rounded"
                value={price}
                onChange={(e) => setPrice(parseInt(e.target.value))}
              />
            </div>
          </div>
          <button
            type="submit"
            className="w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
          >
            Create Event
          </button>
        </form>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold">Event Management</h1>
          <button
            onClick={() => setIsCreatingEvent(!isCreatingEvent)}
            className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
          >
            {isCreatingEvent ? 'View Events' : 'Create Event'}
          </button>
        </div>

        {isCreatingEvent ? (
          <CreateEventForm />
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {events.map(event => (
              <EventCard key={event.id} event={event} />
            ))}
          </div>
        )}

{selectedEvent && (
          <AlertDialog open={!!selectedEvent} onOpenChange={() => setSelectedEvent(null)}>
            <AlertDialogPortal>
              <AlertDialogOverlay className="fixed inset-0 bg-black bg-opacity-50" />
              <AlertDialogContent className="fixed bg-white rounded-lg shadow-md p-6 max-w-md w-full left-1/2 top-1/2 transform -translate-x-1/2 -translate-y-1/2">
                <h2 className="text-xl font-bold mb-4">Register for {selectedEvent.title}</h2>
                <p className="text-gray-600 mb-4">
                  Are you sure you want to register for this event? The cost is ${selectedEvent.price}.
                </p>
                <div className="flex justify-end space-x-4">
                  <button
                    className="bg-gray-200 px-4 py-2 rounded hover:bg-gray-300"
                    onClick={() => setSelectedEvent(null)}
                  >
                    Cancel
                  </button>
                  <button
                    className="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
                    onClick={() => {
                      registerForEvent(selectedEvent.id);
                      setSelectedEvent(null);
                    }}
                  >
                    Confirm
                  </button>
                </div>
              </AlertDialogContent>
            </AlertDialogPortal>
          </AlertDialog>
        )}
      </div>
    </div>
  );
};

export default EventManagementApp;
