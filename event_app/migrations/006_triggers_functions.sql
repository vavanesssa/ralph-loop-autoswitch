-- Create trigger function for automatic profile creation on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, email)
  VALUES (
    NEW.id,
    split_part(NEW.email, '@', 1),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for automatic profile creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Function to update last_read_at timestamp when a message is sent
CREATE OR REPLACE FUNCTION public.update_last_read_on_message(conversation_id_param UUID, user_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.conversation_members
  SET last_read_at = NOW()
  WHERE conversation_id = conversation_id_param
  AND user_id = user_id_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get unread message count for a user in a conversation
CREATE OR REPLACE FUNCTION public.get_unread_count(conversation_id_param UUID, user_id_param UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM public.messages m
    WHERE m.conversation_id = conversation_id_param
    AND m.sender_id != user_id_param
    AND m.created_at > (
      SELECT COALESCE(cm.last_read_at, '1970-01-01')
      FROM public.conversation_members cm
      WHERE cm.conversation_id = conversation_id_param
      AND cm.user_id = user_id_param
    )
  );
END;
$$ LANGUAGE plpgsql;
